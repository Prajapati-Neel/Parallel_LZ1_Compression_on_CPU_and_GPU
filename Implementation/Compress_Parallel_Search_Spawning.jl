import Base.Threads.@threads
using Base.Threads
using Printf, BenchmarkTools

function search(input,start_index_for_input,end_index_for_input,match_data,start,target,window_length,Length)
    for i in start_index_for_input:end_index_for_input
        match_length=0
        if input[i]==input[target]
            current_char=i
            temp_target=target
            while (match_length+target<Length && match_length<window_length && input[current_char]==input[temp_target])
                match_length+=1
                current_char+=1
                temp_target+=1
            end
            match_data[i-start+1]=match_length
        end
     end

end

function Compress_Parallel_Search_Spawning(option_input,search_buffer_length,no_of_search_chunks)#(input,option)
    input_string=read("Input_for_Compression.txt",String)
    Length=length(input_string)

    input=Array{Char}(undef,Length)
    j=0
    for i in eachindex(input_string)
        j+=1
        input[j]=input_string[i]
    end

    look_ahead_buffer_length=20
    window_length=search_buffer_length+look_ahead_buffer_length


    match_data = Array{UInt64}(undef,window_length)
    fill!(match_data,0)
    target=1    #position of character in string

    option=UInt8(option_input)     #1 is for 12-bit, Max 4095  
    # option=UInt8(2)     #2 is for 16-bit, Max 65535

    stream2=open("Debug_Compress_Parallel_Search_findmax.txt", "w")

    if !((option==1 && (search_buffer_length+look_ahead_buffer_length)<=4095)||(option==2 && (search_buffer_length+look_ahead_buffer_length)<=65535))
        println("make sure the search_buffer_length and look_ahead_buffer_length are within limits")
        exit()
    end
    if (option==1)
        stream1=open("Compressed\\Compressed_Parallel_Search_Spawning1.txt", "w")
        write(stream1,UInt8(1)) #to notify the decompressor of option used 
        write(stream1,UInt8(0))
        write(stream1,UInt8(0))
        write(stream1,UInt8(0))
        write(stream1,input[target])
    elseif (option==2)
        stream1=open("Compressed\\Compressed_Parallel_Search_Spawning2.txt", "w")
        write(stream1,UInt8(2)) #to notify the decompressor of option used
        write(stream1,UInt16(0))
        write(stream1,UInt16(0))
        write(stream1,input[target])
    else
        exit()
    end
    write(stream2,@sprintf "%d\n%-8d %-8d %s" option 0 0 input[target])

    target+=1
    current_search_buffer_length=1

    @views while target <= Length
        max_match_length=0
        offset=0
        max_match=0
        fill!(match_data,0)
        tasks = Array{Task}(undef,no_of_search_chunks)
        start=target-current_search_buffer_length
        for i in 1:no_of_search_chunks
            start_index_for_input=start+(fld(current_search_buffer_length,no_of_search_chunks))*(i-1)
            end_index_for_input=start+(fld(current_search_buffer_length,no_of_search_chunks))*(i)-1
            if i==no_of_search_chunks
                end_index_for_input=target-1
            end
            if i==1
                start_index_for_input = start
            end
            tasks[i] = Threads.@spawn search(input,start_index_for_input,end_index_for_input,match_data,start,target,window_length,Length)
        end
        for i in 1:no_of_search_chunks
            wait(tasks[i])
        end
        #  max_match_length, max_match = findmax(match_data)
        for i in 1:window_length
            if (match_data[i]>max_match_length)
                max_match_length=match_data[i]
                max_match=i
            end
        end
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

        write(stream2,@sprintf "\n%-8d %-8d %s  " offset max_match_length input[target])
       target+=1
        if (current_search_buffer_length<search_buffer_length)
            current_search_buffer_length+=max_match_length+1
            if(current_search_buffer_length>search_buffer_length)
                current_search_buffer_length=search_buffer_length
            end
        end
    end
    close(stream1)
    close(stream2)
end

    @btime Compress_Parallel_Search_Spawning(2,65000,12)

# for j in [1,2,4,6,8,12]
#     println("\nno of divisions- ",j, " No of threads- ",Threads.nthreads())
#     # print("4075-")
#     # @btime Compress_Parallel_Search_Spawning(1,4075,$j)
#     print("65000-")
#     @btime Compress_Parallel_Search_Spawning(2,65000,$j)
# end
