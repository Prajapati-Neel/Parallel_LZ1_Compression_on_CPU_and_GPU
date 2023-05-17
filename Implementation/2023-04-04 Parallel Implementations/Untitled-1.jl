using Base.Threads
global a=0
if(threadid()==0)
    a=5

end

@views function Compress_Parallel_Divide_Input(i)
    result1=Array{Int64,1}(undef,i)
    result2=Array{Int64,1}(undef,i)
    result3=Array{Int64,1}(undef,i)
    for j in 1:i
        result1[j]=j
        result2[j]=j
        result3[j]=j
    end
    println
    return result1, result2, result3
end

no_of_chunks=1000
if !(no_of_chunks>0)
    exit()
end
println("Debug_findall_"*string(200)*".txt")
a = Array{Array{Int64}}(undef,no_of_chunks)
c = Array{Array{Int64}}(undef,no_of_chunks)
d = Array{Array{Int64}}(undef,no_of_chunks)
t = Array{Task}(undef,no_of_chunks)
for i in 1:no_of_chunks
    t[i] = Threads.@spawn a[i],d[i],c[i]=Compress_Parallel_Divide_Input(i)
end
for i in 1:no_of_chunks
wait(t[i])
end

# println(a)

s=Array{String}(undef,5)
s[1]="asd"

# io = IOBuffer();
# write(io,'a')
# flush(io)
# write_stream=open("test.txt", "w")
# print(position(write_stream))
# write(write_stream,"1")
# write(write_stream,"1")
# write(write_stream,"1")
# write(write_stream,"2")
# print(position(write_stream))
# close(write_stream)

# read_stream=open("test.txt", "r")
# seek(read_stream,3)
# print(read(read_stream,Char))