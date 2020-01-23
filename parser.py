import os, sys

code = []
stack = []
var_table = {}
label_table = {}
func_table = {}
eip = 0
printout = []

def assemb(asmfilename):

	label = ""
	for line in open(asmfilename):
		line = line.strip()
		_label, sep, ist = line.partition(':')
		if sep and _label.find('"') == -1 and _label.find("'") == -1:
			_label, ist = _label.strip(), ist.strip()
			if not check_label(_label):
				print(line, "Wrong label")
			label = '%s,%s' % (label, _label) if label else _label
			if ist == "":continue
		elif len(line) >= 7 and line[:7] == 'ENDFUNC':
			label = '%s,%s' % (label, 'ENDFUNC') \
											if label else 'ENDFUNC'
			ist = 'ret'
		else:
			ist = line

		dire, sep, arg = ist.partition(' ')
		if dire == "":continue
		code.append( [label, dire, arg.strip()] )
		label = ""

	code.append(('', 'exit', '0'))

def check_label(label):
	if label == "":
		return False

	func, sep, funcName = label.partition(' @')

	if sep:
		if func.strip() != 'FUNC' \
			or funcName in func_table:
			return False
		else:
			func_table[funcName] = len(code)
			return True
	else:
		if  label in func_table \
			or label in label_table:
			return False
		else:
			label_table[label] = len(code)
			return True

def run():
	global eip
	eip = 0
	del stack[:]

	while True:
		label, dire, arg = code[eip]
		if dire[0] == '$':
			action, arg = call, dire[1:]
		elif label == 'ENDFUNC':
			exit(0)
		else:
			try:
				action = eval("do_" + dire)
			except NameError:
				print("Unknown instruction")
		action(arg)
		eip += 1

def do_var(arg):
	if arg == "": return
	for var in arg.split(','):
		var = var.strip()
		var_table[var] = len(stack)
		var_table[len(stack)] = var
		#in var_table,you can find vairable with the location in stack,also find the varieble location in stack with variable in var_table
		stack.append("/")

def do_push(arg):
	try:
		arg = int(arg)
	except ValueError:
		try:
			arg = stack[var_table[arg]]
		except KeyError:
			print("Undefined variable")
		if type(arg) is not int:
			print("Cannot push uninitialed value")
	stack.append(arg)

def do_pop(arg):
	value = stack.pop()
	if arg == "":
		return
	try:
		stack[var_table[arg]] = value
	except KeyError:
		print("Undefined variable")

def do_exit(arg):
	global going, exit_code
	going = False

	if arg == "~":
		exit_code = stack[-1]
	elif arg:
		try:
			exit_code = int(arg)
		except ValueError:
			try:
				exit_code = stack[var_table[arg]]
			except KeyError:
				print("Undefined variable")

	if type(exit_code) is not int:
		print("Wrong exit code")
	exit(exit_code)


def do_add(arg):   stack[-2] += stack[-1]; stack.pop()
def do_sub(arg):   stack[-2] -= stack[-1]; stack.pop()
def do_mul(arg):   stack[-2] *= stack[-1]; stack.pop()
def do_div(arg):   stack[-2] /= stack[-1]; stack.pop()
def do_mod(arg):   stack[-2] %= stack[-1]; stack.pop()
def do_and(arg):   stack[-2] = int(stack[-2]!=0 and stack[-1]!=0); stack.pop()
def do_or(arg):    stack[-2] = int(stack[-2]!=0 or  stack[-1]!=0); stack.pop()
def do_cmpeq(arg): stack[-2] = int(stack[-2]==stack[-1]);stack.pop()
def do_cmpne(arg): stack[-2] = int(stack[-2]!=stack[-1]);stack.pop()
def do_cmpgt(arg): stack[-2] = int(stack[-2]>stack[-1]); stack.pop()
def do_cmplt(arg): stack[-2] = int(stack[-2]<stack[-1]); stack.pop()
def do_cmpge(arg): stack[-2] = int(stack[-2]>=stack[-1]);stack.pop()
def do_cmple(arg): stack[-2] = int(stack[-2]<=stack[-1]);stack.pop()
def do_neg(arg):   stack[-1] = -stack[-1]
def do_not(arg):   stack[-1] = int(not stack[-1])

def do_print(fmt):
	argc = fmt.count("%d")
	out = fmt[1:-1] % tuple(stack[len(stack)-argc:])
	print (out)
	printout.append(out)
	del stack[len(stack)-argc:]

def do_input(msg):
	msg = msg.strip('"').strip("'")
	string = input(msg)
	try:
		value = int(string)
	except ValueError:
		value = 0
	stack.append(value)
	printout.append("\n  " + msg + str(value))

def do_jmp(label):
	global eip
	try:
		# note: here we set eip just befor the label,
		#       and when back to run(), we do eip += 1
		eip = label_table[label] - 1
	except KeyError:
		print("Wrong label")

def do_jz(label):
	global eip
	try:
		# set eip just befor the label,
		# when back to run(), do eip += 1
		new_eip = label_table[label] - 1
	except KeyError:
		print(label_table)
		print("Wrong label")
	if stack.pop() == 0:
		eip = new_eip

def call(funcName):
	global var_table, eip

	try:
		entry = func_table[funcName]
	except KeyError:
		print("Undefined function")

	if code[entry][1] == "arg":
		arg_list = code[entry][2].split(',')
	else:
		arg_list = []

	new_var_table = {}
	for addr, arg  in enumerate(arg_list, len(stack)-len(arg_list)):
		arg = arg.strip()
		new_var_table[arg] = addr
		new_var_table[addr] = arg

	stack.append( (len(arg_list), eip, var_table) )
	var_table = new_var_table
	eip = entry  if len(arg_list) else entry - 1

def do_ret(arg):
	global var_table, eip

	if arg == "~":
		retval = stack[-1]
	elif arg:
		try:
			retval = int(arg)
		except ValueError:
			try:
				retval = stack[var_table[arg]]
			except KeyError:
				print("Undefined variable")
	else:
		retval = '/'

	i = len(stack) - 1
	while type(stack[i]) is not tuple and i != 0:
		i -= 1
	if i == 0:return
	argc, eip, var_table = stack[i]
	del stack[i-argc:]
	stack.append(retval)

if __name__ == "__main__":
	asmfileName = sys.argv[1]
	assemb(asmfileName)
	run()