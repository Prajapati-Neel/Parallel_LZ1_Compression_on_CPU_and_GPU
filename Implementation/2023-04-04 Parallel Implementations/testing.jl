using BenchmarkTools
using Printf

# # Number1=UInt16(1)
# # Number2=UInt16(767)
# stream=open("my_file.txt", "w")
# # write(stream,a)
# # write(stream,Char(65000))
# # write(stream,UInt16(5000))
# write(stream,Char(30000))
# write(stream,Char(55))
# close(stream)

# print(a[5])
# println(prevind(a,5,-1))
# print(length(a[1:8]))
# for i in eachindex(a[3:7])
#     println(i)
# end












input=read("my_file.txt",String)
length(input)
a=""
b=a*"as"
target=1;
char_to_find = '-'
function find(input,char_to_find)
    indices = findall(c -> c == char_to_find, input);
    
end

function withloop(input,char_to_find)
    # d=Vector{Int64}(undef, 100000000)
    # for i in eachindex(input)
    t=1
    for i in 1:length(input)
        
        if input[nextind(input,i-1)]==char_to_find
        #    d[t]=nextind(input,i-1)                                                                                                    
        #    t+=1
        end
    end
    # return d
end
function withloopeachindex(input,char_to_find)
    # d=Vector{Int64}(undef, 100000000)
    # for i in eachindex(input)
    t=1
    for i in eachindex(input)
        
        if input[i]==char_to_find
        #    d[t]=nextind(input,i-1)                                                                                                    
        #    t+=1
        end
    end
    # return d
end
# @btime withloop(input,char_to_find)
# @btime withloopeachindex(input,char_to_find);

# @btime find(input,char_to_find);


# Number1_lower_8bits=UInt8(Number1%256)
# Number1_upper_4bits=fld(Number1,256)

# Number2_lower_8bits=UInt8(Number2%256)
# Number2_upper_4bits=fld(Number2,256)*16
# Upper_bits_of_Numbers=UInt8(Number1_upper_4bits+Number2_upper_4bits)

# Number1_back_upper_4bits=Upper_bits_of_Numbers%16
# Number1_back=Number1_back_upper_4bits*256+Number1_lower_8bits
# Number2_back_upper_4bits=fld(Upper_bits_of_Numbers,16)
# Number2_back=Number2_back_upper_4bits*256+Number2_lower_8bits
