#!/usr/bin/ruby

$Env = []

def CAR(l)
  return l[0]
end

def CDR(l)
  return l[1..-1]
end

def typeof(x)
	if x.instance_of? Array
		return "Array"
	elsif  x =~ /^[0-9]+/
		return "INT"
        else
             return "SYM"
	end
end

def PRINT(arg)
  if typeof(arg) == "Array"
    "(#{arg.map { |e| PRINT e }.join ' ' })"
  else
    arg.to_s
  end
end

def PAIRLIS (key, val, env)
  if not key
    return env
  else 
      if CAR(key) != nil
	  env.unshift([CAR(key),CAR(val)] ) 
	  PAIRLIS(CDR(key),CDR(val),env)
         end
   end
  return env
end

def ASSOC(key, env)
  if env.length() == 0
   print  ("variable not bound " + key)
   return []
   elsif env[0][0] == key
      return env[0][1]
   else 
     return ASSOC(key,env[1..-1])
  end
end

def set(key, val, env)                  #  return a variable binding          
  if env.length() == 0
   print ("variable not bound: " + key + "\n") 
   return 'NIL'
   else
    x = 0
    env.each do
     if env[x][0] == key
       env[x][1] = val[1]
       return 
       x = x + 1
     end
   end
    
  end
end

def evcon (c, env)
    if c.length() == 0 
      return []
    elsif EVAL(c[0][0], env) != 'NIL' 
       return EVAL(c[0][1],env)
    else
      return evcon(c[1..-1],env)
    end
end


def EVLIS (l, env)
  if l.length() == 0 
     return []
    else  
     return [EVAL(CAR(l), env)] + EVLIS(CDR(l), env)
     end
end

def APPLY (fn,args,env)
    if typeof(fn)=='SYM'   # name of a function
        if fn == 'atom' 
          if typeof(args[0]) == 'Array'
            return 'NIL'
            else
           return 't'
           end
        elsif fn == 'car'
             return args[0][0] # first element of 1st arg
        elsif fn == 'null?'
             if args[0].length() < 1
              return 't'
             else 
              return 'NIL'
             end
        elsif fn == 'cdr'
             return args[0][1..-1]  # tail of 1st arg
        elsif fn == '+' 
             return args.reduce(0) { |sum, num| sum.to_i + num.to_i }
        elsif fn == '-'   
          return args.inject{ |acc, x| acc.to_i - x.to_i }
        elsif fn == '*'  
             return args.inject{ |acc, x| acc.to_i * x.to_i }
        elsif fn == '/'    
             return args.inject{ |acc, x| acc.to_i / x.to_i }
        elsif fn == '>'                
             if args[0].to_i > args[1].to_i
               return 't'
             else 
               return 'NIL'
             end
        elsif fn == '<'    
             if args[0].to_i < args[1].to_i
               return 't'
             else 
               return 'NIL'
             end
        elsif fn == 'eq'   
          if args[0].to_s == args[1].to_s
            return 't'
           else 
             return 'NIL'
          end
        elsif fn == 'not'   
           if args[0].to_s != args[1].to_s
            return 't'
            else
              return 'NIL'
           end
        elsif fn == 'cons' 
            if typeof(args[1]) != 'Array' 
                   args[1] = [args[1]]
            return [args[0]] + args[1]
            end
        else 
            return APPLY(EVAL(fn,env),args,env)
         end
    elsif fn[0] == 'lambda' 
        return EVAL(fn[2], PAIRLIS(fn[1],args,env))
    else                   
      print "Can't APPLY "
   end
end
################################ EVAL #################################

def EVAL (exp, env)
    if   exp == 't' 
      return 't'      # true evaluates to itself
    elsif exp == 'nil'
       return 'NIL'       # symbol nil same as a null list
    elsif exp == 'env'
        return $Env    # special command to examine env
    elsif typeof(exp) == 'INT'
      return exp      # numbers eval to themselves
   elsif typeof(exp) == "SYM"
      result = ASSOC(exp,env)  # look up variables
      return result 
    else                # check for special forms
        if exp[0] == 'quote' || exp[0] == "'"
            return exp[1]
        elsif exp[0] == 'set!'
              set(exp[1],exp[1..-1], env)
               return exp[1]
        elsif exp[0] == 'define'             # user define functions
            env = $Env = PAIRLIS([exp[1]],[exp[2]],env)
            return exp[1]                 # return function name
        elsif exp[0] == 'cond'
            return evcon(exp[1..-1], env)
        else 
            x = EVLIS(exp[1..-1], env) 

            return APPLY(exp[0],x, env)
        end
    end
end

##############################  READ ##################################
def READ str
  read_from tokenize str
end

def tokenize(str)
 str = str.gsub("(" , " ( ").gsub(")", " ) ").split
 return str
end

def read_from tokens
  raise SytaxError, 'unexpected EOF while reading' if tokens.length.zero? 
  token = tokens.shift
  if '(' == token
    l = []
    until tokens[0] == ')'
      l << read_from( tokens )
    end
    tokens.shift # pop off ')'
    return l
  elsif ')' == token
    raise SyntaxError, 'unexpected )'
  else
    return token
  end
end
########################################################################

def repl
 lp = rp = 0
 print ">"
 command = ""
while true
 inputstr = gets
 inputstr = inputstr.gsub('\n', '')
 if inputstr !~/[\S]+/
   print ">"
   next
 elsif inputstr =~/^exit/
   exit
 end
 lcount = inputstr.count('(')
 rcount = inputstr.count(')')
 lp = lp + lcount
 rp = rp + rcount

 if rp > lp 
   print "ERROR: Unbalanced Parens\n>"
   rp = lp = 0
   next
 end
 inputstr = inputstr.strip
 command.concat(inputstr)
  if lp == rp
   tokens = READ(command)
   print(PRINT(EVAL(tokens ,$Env)))
   command = ""
   print "\n"
   print ">"
  end
 end
end

repl()
