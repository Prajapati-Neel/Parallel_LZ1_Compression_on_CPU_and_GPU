using Base.Threads,CUDA
const MAX_THREADS_PER_BLOCK = CUDA.attribute(CUDA.CuDevice(0), CUDA.DEVICE_ATTRIBUTE_MAX_THREADS_PER_BLOCK,)

xtring=read("Input_for_Compression.txt",String)
xtring="a"
search="Copyright © 2012, Oracle and/or its affiliates. All rights reserved. Oracle and Java are registered trademarks of Oracle and/or its affiliates. Other names may be trademarks of their respective owners. 113940"
c = Array{Char}(undef,length(xtring))
search_array=Array{Char}(undef,length(search))
j=0
for i in eachindex(xtring)
    global j+=1
    c[j]=xtring[i]
end
j=0
for i in eachindex(search)
    global j+=1
    search_array[j]=search[i]
end
search_d=CuArray{eltype(search_array)}(search_array)
c_d=CuArray{eltype(c)}(c)

d = Array{UInt64}(undef,length(xtring))

function array_search_CuNative(a_d,search_d)
    d = Array{UInt64}(undef,length(xtring))
    fill!(d,0)
    length_a_d = length(a_d)
    length_search_d = length(search_d)
    for i in 1:20
        global d_d = CuArray{eltype(d)}(d)
        @cuda blocks=cld(length_a_d, MAX_THREADS_PER_BLOCK) threads=MAX_THREADS_PER_BLOCK searchKernel(a_d,d_d,search_d,length_a_d,length_search_d)
    end
    a,b=findmax(d_d)
    # for i in b:b+a-1
    #     print(a_d[i])
    # end
end
function searchKernel(a_d,d_d,search_d,length_a_d,length_search_d)
    id = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    j=0
    if id<=length_a_d && a_d[id]==search_d[1]
        x=id
        while(j<=length_search_d && x<=length_a_d && a_d[x]==search_d[j])
            j+=1
            x+=1
        end
        d_d[id]=j
    end
    return nothing
end
CUDA.@time array_search_CuNative(c_d,search_d)
CUDA.@time array_search_CuNative(c_d,search_d)
CUDA.@time array_search_CuNative(c_d,search_d)
CUDA.@time array_search_CuNative(c_d,search_d)
CUDA.@time array_search_CuNative(c_d,search_d)
CUDA.@time array_search_CuNative(c_d,search_d)
CUDA.@time array_search_CuNative(c_d,search_d)

