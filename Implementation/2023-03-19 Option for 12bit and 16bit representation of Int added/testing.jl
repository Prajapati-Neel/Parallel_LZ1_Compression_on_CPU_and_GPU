using BenchmarkTools
using Printf

# Number1=UInt16(1)
# Number2=UInt16(767)
stream=open("my_file.txt", "w")
# write(stream,a)
# write(stream,Char(65000))
# write(stream,UInt16(5000))
write(stream,Char(30000))
write(stream,Char(55))
# write(stream,@sprintf "%d%d%c" UInt8(12) UInt8(12) Char(25))
close(stream)
for Number1 in 0:4095
    for Number2 in 0:4095

        Number1_lower_8bits=UInt8(Number1%256)
        Number1_upper_4bits=fld(Number1,256)

        Number2_lower_8bits=UInt8(Number2%256)
        Number2_upper_4bits=fld(Number2,256)*16
        Upper_bits_of_Numbers=UInt8(Number1_upper_4bits+Number2_upper_4bits)

        Number1_back_upper_4bits=Upper_bits_of_Numbers%16
        Number1_back=Number1_back_upper_4bits*256+Number1_lower_8bits
        Number2_back_upper_4bits=fld(Upper_bits_of_Numbers,16)
        Number2_back=Number2_back_upper_4bits*256+Number2_lower_8bits
        if(Number1!=Number1_back || Number1!=Number1_back ) 
            print(Number1,Number2)
        end
  
    end
end

# Number_back=c*256+b
# println(Number1," ",bitstring(Number1))
# println(Number1_back," ",bitstring(Number1_back))
# # println(Number1_lower_8bits," ",bitstring(Number1_lower_8bits))
# # println(Number1_upper_4bits," ",bitstring(Number1_upper_4bits))
# println(Number2," ",bitstring(Number2))
# println(Number2_back," ",bitstring(Number2_back))
# # println(Number2_lower_8bits," ",bitstring(Number2_lower_8bits))
# # println(Number2_upper_4bits," ",bitstring(Number2_upper_4bits))
# # println(Upper_bits_of_Numbers," ",bitstring(Upper_bits_of_Numbers))
stream=open("my_file.txt", "r")
i=0
while(!eof(stream))
    # println(read(stream,UInt16))
    # println(read(stream,Char))
    # println(read(stream,UInt16))
    print(read(stream,Char))
end
close(stream)
# input[3483]
# length(input)
# a=""
# b=a*"as"
# target=1;
# char_to_find = '-'
# function find(input,char_to_find)
#     indices = findall(c -> c == char_to_find, input)
    
# end

# function withloop(input,char_to_find)
#     for i in 1:length(input)
#         d=0
#         if input[i]==char_to_find
#             d=i
#         end
#         d+=1
#     end
# end
# @btime withloop(input,char_to_find)
# @btime find(input,char_to_find)
