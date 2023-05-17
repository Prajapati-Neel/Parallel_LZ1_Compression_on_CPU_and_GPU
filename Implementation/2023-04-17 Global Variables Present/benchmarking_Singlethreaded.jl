# stream=open("my_file.txt", "r")
# stream=open("my_file1.txt", "w")
# write(stream,input)
# close(stream)
using Printf, BenchmarkTools
using Base.Threads, CUDA
const MAX_THREADS_PER_BLOCK = CUDA.attribute(CUDA.CuDevice(0), CUDA.DEVICE_ATTRIBUTE_MAX_THREADS_PER_BLOCK,)

# if(Length<200)
#     exit()
# end

function Compress_eachindex(option_input,search_buffer_length)#(input,option)
    input=read("Input_for_Compression.txt",String)
    option=UInt8(option_input)     #1 is for 12-bit, Max 4095  
    # option=UInt8(2)     #2 is for 16-bit, Max 65535
    # search_buffer_length=4075
    look_ahead_buffer_length=20
    Length=length(input)
    global target=1    #position of character in string
    global target_index=1  #index of character in string

    stream1=open("Compressed_eachindex.txt", "w")
    stream2=open("Debug_eachindex.txt", "w")


    if !((option==1 && (search_buffer_length+look_ahead_buffer_length)<=4095)||(option==2 && (search_buffer_length+look_ahead_buffer_length)<=65535))
        println("make sure the search_buffer_length and look_ahead_buffer_length are within limits")
        exit()
    end
    if (option==1)
        write(stream1,UInt8(1)) #to notify the decompressor of option used 
        write(stream1,UInt8(0))
        write(stream1,UInt8(0))
        write(stream1,UInt8(0))
        write(stream1,input[target_index])
    elseif (option==2)
        write(stream1,UInt8(2)) #to notify the decompressor of option used
        write(stream1,UInt16(0))
        write(stream1,UInt16(0))
        write(stream1,input[target_index])
    else
        exit()
    end
    write(stream2,@sprintf "%d\n%-8d %-8d %s" option 0 0 input[target_index])

    target+=1
    global target_index=nextind(input,1)
    global current_search_buffer_length=1

    @views while target <= Length
        max_match= 0
        max_match_length=0
        c=input[target_index]
        i=current_search_buffer_length
        eachindex_correction=prevind(input,target_index,current_search_buffer_length)-1 
        for index in eachindex(input[prevind(input,target_index,current_search_buffer_length):prevind(input,target_index)])
            if max_match_length==search_buffer_length+look_ahead_buffer_length
                break
            end
            match_length=0
            index+=eachindex_correction #eachindex() always returns an iterator that starts from 1 to correct this the index of first character of range prevind(input,target_index,current_search_buffer_length) has been added.
            while ((match_length<search_buffer_length+look_ahead_buffer_length) && (match_length+target<length(input)) &&(input[nextind(input,index,match_length)]==input[nextind(input,target_index,match_length)])) 
            match_length+=1
            end
            if match_length>max_match_length
                max_match=i
                max_match_length=match_length
            end
            if max_match_length==search_buffer_length+look_ahead_buffer_length
                break
            end
            i-=1
        end
        offset=max_match

        if (option==1)
            offset_lower_8bits=UInt8(offset%256)
            offset_upper_4bits=fld(offset,256)

            max_match_length_lower_8bits=UInt8(max_match_length%256)
            max_match_length_upper_4bits=fld(max_match_length,256)*16
            Upper_bits_of_Numbers=UInt8(offset_upper_4bits+max_match_length_upper_4bits)

            write(stream1,UInt8(Upper_bits_of_Numbers))
            write(stream1,UInt8(offset_lower_8bits))
            write(stream1,UInt8(max_match_length_lower_8bits))

        elseif (option==2)
            write(stream1,UInt16(offset))
            write(stream1,UInt16(max_match_length))
        end
        write(stream1,input[nextind(input,target_index,max_match_length)])#input[target+max_match_length])

        write(stream2,@sprintf "\n%-8d %-8d %s  " offset max_match_length input[nextind(input,target_index,max_match_length)])
        if max_match!=0
            if (offset-max_match_length+1)<0
                write(stream2,@sprintf "matched-\'%s\'" input[prevind(input,target_index,offset):nextind(input,target_index,max_match_length-offset-1)])#input[max_match:max_match+max_match_length-1])
            else
                write(stream2,@sprintf "matched-\'%s\'" input[prevind(input,target_index,offset):prevind(input,target_index,offset-max_match_length+1)])#input[max_match:max_match+max_match_length-1])
            end
        end
        global target+=max_match_length+1
        global target_index=nextind(input,target_index,max_match_length+1)
        if (current_search_buffer_length<search_buffer_length)
            global current_search_buffer_length+=max_match_length+1
            if(current_search_buffer_length>search_buffer_length)
                current_search_buffer_length=search_buffer_length
            end
        end
    end
    close(stream1)
    close(stream2)
end


function Compress_findall(option_input,search_buffer_length)#(input,option)
    input=read("Input_for_Compression.txt",String)
    option=UInt8(option_input)     #1 is for 12-bit, Max 4095  
    # option=UInt8(2)     #2 is for 16-bit, Max 65535
    # search_buffer_length=4075
    look_ahead_buffer_length=20
    Length=length(input)
    global target=1    #position of character in string
    global target_index=1  #index of character in string

    stream1=open("Compressed_findall.txt", "w")
    stream2=open("Debug_findall.txt", "w")


    if !((option==1 && (search_buffer_length+look_ahead_buffer_length)<=4095)||(option==2 && (search_buffer_length+look_ahead_buffer_length)<=65535))
        println("make sure the search_buffer_length and look_ahead_buffer_length are within limits")
        exit()
    end
    if (option==1)
        write(stream1,UInt8(1)) #to notify the decompressor of option used 
        write(stream1,UInt8(0))
        write(stream1,UInt8(0))
        write(stream1,UInt8(0))
        write(stream1,input[target_index])
    elseif (option==2)
        write(stream1,UInt8(2)) #to notify the decompressor of option used
        write(stream1,UInt16(0))
        write(stream1,UInt16(0))
        write(stream1,input[target_index])
    else
        exit()
    end
    write(stream2,@sprintf "%d\n%-8d %-8d %s" option 0 0 input[target_index])

    target+=1
    global target_index=nextind(input,1)
    global current_search_buffer_length=1

    @views while target <= Length
        max_match= 0
        max_match_length=0
        c=input[target_index]
        eachindex_correction=prevind(input,target_index,current_search_buffer_length)-1
        matches=findall(c -> c == input[target_index], input[prevind(input,target_index,current_search_buffer_length):prevind(input,target_index)]) 
        for index in matches
            if max_match_length==search_buffer_length+look_ahead_buffer_length
                break
            end
            if target < Length
                match_length=1
            else
                match_length=0
            end
            index+=eachindex_correction #eachindex() always returns an iterator that starts from 1 to correct this the index of first character of range prevind(input,target_index,current_search_buffer_length) has been added.
            while ((match_length<search_buffer_length+look_ahead_buffer_length) && (match_length+target<length(input)) &&(input[nextind(input,index,match_length)]==input[nextind(input,target_index,match_length)])) 
            match_length+=1
            end
            if match_length>max_match_length
                max_match=length(input[index:target_index])-1
                max_match_length=match_length
            end
            if max_match_length==search_buffer_length+look_ahead_buffer_length
                break
            end
        end
        offset=max_match

        if (option==1)
            offset_lower_8bits=UInt8(offset%256)
            offset_upper_4bits=fld(offset,256)

            max_match_length_lower_8bits=UInt8(max_match_length%256)
            max_match_length_upper_4bits=fld(max_match_length,256)*16
            Upper_bits_of_Numbers=UInt8(offset_upper_4bits+max_match_length_upper_4bits)

            write(stream1,UInt8(Upper_bits_of_Numbers))
            write(stream1,UInt8(offset_lower_8bits))
            write(stream1,UInt8(max_match_length_lower_8bits))

        elseif (option==2)
            write(stream1,UInt16(offset))
            write(stream1,UInt16(max_match_length))
        end
        write(stream1,input[nextind(input,target_index,max_match_length)])#input[target+max_match_length])

        write(stream2,@sprintf "\n%-8d %-8d %s  " offset max_match_length input[nextind(input,target_index,max_match_length)])
        if max_match!=0
            if (offset-max_match_length+1)<0
                write(stream2,@sprintf "matched-\'%s\'" input[prevind(input,target_index,offset):nextind(input,target_index,max_match_length-offset-1)])#input[max_match:max_match+max_match_length-1])
            else
                write(stream2,@sprintf "matched-\'%s\'" input[prevind(input,target_index,offset):prevind(input,target_index,offset-max_match_length+1)])#input[max_match:max_match+max_match_length-1])
            end
        end
        global target+=max_match_length+1
        global target_index=nextind(input,target_index,max_match_length+1)
        if (current_search_buffer_length<search_buffer_length)
            global current_search_buffer_length+=max_match_length+1
            if(current_search_buffer_length>search_buffer_length)
                current_search_buffer_length=search_buffer_length
            end
        end
    end
    close(stream1)
    close(stream2)
end

function searchKernel(input_d,length_input_d,target,current_search_buffer_length,window_length,match_data_d)
    id = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    match_length=0
    current_char=target-current_search_buffer_length+id-1
    if id<=current_search_buffer_length && input_d[current_char]==input_d[target]
        while (target<length_input_d && match_length<=window_length && input_d[current_char]==input_d[target])
            match_length+=1
            current_char+=1
            target+=1
        end
        match_data_d[id]=match_length
    end
    return nothing
end

function Compress_GPU_Parallel_Search(option_input,search_buffer_length)#(input,option)
    input_string=read("Input_for_Compression.txt",String)
    input=Array{Char}(undef,length(input_string))
    j=0
    for i in eachindex(input_string)
        j+=1
        input[j]=input_string[i]
    end

    # search_buffer_length=4075
    look_ahead_buffer_length=20
    window_length=search_buffer_length+look_ahead_buffer_length

    input_d=CuArray{eltype(input)}(input)
    length_input_d=length(input_d)

    match_data_zeros = Array{UInt64}(undef,window_length)
    fill!(match_data_zeros,0)
    global target=1    #position of character in string

    option=UInt8(option_input)     #1 is for 12-bit, Max 4095  
    # option=UInt8(2)     #2 is for 16-bit, Max 65535

    stream1=open("Compressed_GPU_Parallel_Search.txt", "w")
    stream2=open("Debug_Compress_Parallel_Search.txt", "w")


    if !((option==1 && (search_buffer_length+look_ahead_buffer_length)<=4095)||(option==2 && (search_buffer_length+look_ahead_buffer_length)<=65535))
        println("make sure the search_buffer_length and look_ahead_buffer_length are within limits")
        exit()
    end
    if (option==1)
        write(stream1,UInt8(1)) #to notify the decompressor of option used 
        write(stream1,UInt8(0))
        write(stream1,UInt8(0))
        write(stream1,UInt8(0))
        write(stream1,input[target])
    elseif (option==2)
        write(stream1,UInt8(2)) #to notify the decompressor of option used
        write(stream1,UInt16(0))
        write(stream1,UInt16(0))
        write(stream1,input[target])
    else
        exit()
    end
    # write(stream2,@sprintf "%d\n%-8d %-8d %s" option 0 0 input[target])

    target+=1
    global current_search_buffer_length=1
    match_data_d=CuArray{eltype(match_data_zeros)}(match_data_zeros)

    while target <= length_input_d
        offset=0
        # match_data_d=CuArray{eltype(match_data_zeros)}(match_data_zeros)
        fill!(match_data_d,0)
        @cuda blocks=cld(current_search_buffer_length, MAX_THREADS_PER_BLOCK) threads=MAX_THREADS_PER_BLOCK searchKernel(input_d,length_input_d,target,current_search_buffer_length,window_length,match_data_d)
        max_match_length, max_match = findmax(match_data_d)
        if max_match_length>0
            offset=current_search_buffer_length-max_match+1
        end
        target+=max_match_length
        if (option==1)
            offset_lower_8bits=UInt8(offset%256)
            offset_upper_4bits=fld(offset,256)

            max_match_length_lower_8bits=UInt8(max_match_length%256)
            max_match_length_upper_4bits=fld(max_match_length,256)*16
            Upper_bits_of_Numbers=UInt8(offset_upper_4bits+max_match_length_upper_4bits)

            write(stream1,UInt8(Upper_bits_of_Numbers))
            write(stream1,UInt8(offset_lower_8bits))
            write(stream1,UInt8(max_match_length_lower_8bits))

        elseif (option==2)
            write(stream1,UInt16(offset))
            write(stream1,UInt16(max_match_length))
        end
        write(stream1,input[target])

        # write(stream2,@sprintf "\n%-8d %-8d %s  " offset max_match_length input[target])
        # flush(stream2)
        # write(stream2,@sprintf "\n%-8d %-8d %s  " offset max_match_length input[nextind(input,target_index,max_match_length)])
        # if max_match!=0
        #     if (offset-max_match_length+1)<0
        #         write(stream2,@sprintf "matched-\'%s\'" input[prevind(input,target_index,offset):nextind(input,target_index,max_match_length-offset-1)])#input[max_match:max_match+max_match_length-1])
        #     else
        #         write(stream2,@sprintf "matched-\'%s\'" input[prevind(input,target_index,offset):prevind(input,target_index,offset-max_match_length+1)])#input[max_match:max_match+max_match_length-1])
        #     end
        # end
        target+=1
        if (current_search_buffer_length<search_buffer_length)
            global current_search_buffer_length+=max_match_length+1
            if(current_search_buffer_length>search_buffer_length)
                current_search_buffer_length=search_buffer_length
            end
        end
    end
    close(stream1)
    close(stream2)
end
println("\n\n Findall search_buffer_length-4075")
@btime Compress_findall(1,4075)
@btime Compress_findall(1,4075)

println("\n\n Findall search_buffer_length-65000")
@btime Compress_findall(2,65000)
@btime Compress_findall(2,65000)


println("\n\n eachindex search_buffer_length-4075")
@btime Compress_eachindex(1,4075)
@btime Compress_eachindex(1,4075)


println("\n\n eachindex search_buffer_length-65000")
@btime Compress_eachindex(2,65000)
@btime Compress_eachindex(2,65000)


GC.gc(true)

println("\n\n GPU search_buffer_length-4075")
CUDA.@time Compress_GPU_Parallel_Search(1,4075)
CUDA.@time Compress_GPU_Parallel_Search(1,4075)
CUDA.@time Compress_GPU_Parallel_Search(1,4075)
println("\n\n GPU search_buffer_length-65000")
CUDA.@time Compress_GPU_Parallel_Search(2,65000)
CUDA.@time Compress_GPU_Parallel_Search(2,65000)
CUDA.@time Compress_GPU_Parallel_Search(2,65000)
GC.gc(true)
