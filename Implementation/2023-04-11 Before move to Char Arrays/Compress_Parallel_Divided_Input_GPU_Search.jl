using Printf, BenchmarkTools, CUDA
using Base.Threads
const MAX_THREADS_PER_BLOCK = CUDA.attribute(CUDA.CuDevice(0), CUDA.DEVICE_ATTRIBUTE_MAX_THREADS_PER_BLOCK,)

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

function Compress_Parallel_Divided_Input_GPU_Search(option_input,search_buffer_length)
    input=read("Input_for_Compression.txt",String)
    output=open("Compressed_Parallel_Divided_Input.txt", "w")
    option=UInt8(option_input) 
    # search_buffer_length=4075
    look_ahead_buffer_length=20
    Length=length(input)
    no_of_chunks=12
 
    if !((option==1 && (search_buffer_length+look_ahead_buffer_length)<=4095)||(option==2 && (search_buffer_length+look_ahead_buffer_length)<=65535))
        println("make sure the search_buffer_length and look_ahead_buffer_length are within limits")
        exit()
    end
    Collected_Results_following_character=Array{Array{UInt64}}(undef,no_of_chunks)
    Lengths_of_Compressed_Chunks=Array{UInt64}(undef,no_of_chunks)

    if (option==1)
        Collected_Results_Upper_bits_of_Numbers = Array{Array{UInt8}}(undef,no_of_chunks)
        Collected_Results_offset_lower_8bits = Array{Array{UInt8}}(undef,no_of_chunks)
        Collected_Results_max_match_length_lower_8bits = Array{Array{UInt8}}(undef,no_of_chunks)
        # tasks = Array{Task}(undef,no_of_chunks)
        @threads for i in 1:no_of_chunks
            chunk_start_index = nextind(input,1,(fld(Length,no_of_chunks))*(i-1))
            chunk_end_index = nextind(input,1,(fld(Length,no_of_chunks))*(i)-1)
            if i==no_of_chunks
                chunk_end_index=lastindex(input)
                lastindex
            end
            # if i==1
            #     chunk_start_index = 1
            # end
            # tasks[i] = Threads.@spawn Collected_Results_Upper_bits_of_Numbers[i], Collected_Results_offset_lower_8bits[i], Collected_Results_max_match_length_lower_8bits[i], Collected_Results_following_character[i], Lengths_of_Compressed_Chunks[i] = Compress_findall(input[chunk_start_index:chunk_end_index], option, search_buffer_length, look_ahead_buffer_length, chunk_start_index)
            Collected_Results_Upper_bits_of_Numbers[i], Collected_Results_offset_lower_8bits[i], Collected_Results_max_match_length_lower_8bits[i], Collected_Results_following_character[i], Lengths_of_Compressed_Chunks[i] = Compress_GPU_Parallel_Search(input[chunk_start_index:chunk_end_index], option, search_buffer_length, look_ahead_buffer_length, chunk_start_index)
        end
        # for i in 1:no_of_chunks
        #     wait(tasks[i])
        # end
        write(output,UInt8(1)) #to notify the decompressor of option used 
        write(output,UInt8(no_of_chunks))
        for i in 1:no_of_chunks
            write(output,UInt64(0))
            write(output,UInt64(Lengths_of_Compressed_Chunks[i]))
        end
        for i in 1:no_of_chunks
            for j in 1:Lengths_of_Compressed_Chunks[i]
                write(output,UInt8(Collected_Results_Upper_bits_of_Numbers[i][j]))
                write(output,UInt8(Collected_Results_offset_lower_8bits[i][j]))
                write(output,UInt8(Collected_Results_max_match_length_lower_8bits[i][j]))
                write(output,Char(Collected_Results_following_character[i][j]))
            end
            current_position=position(output)
            seek(output,(((i-1)*16)+2))
            write(output,UInt64(current_position))
            seek(output,current_position)
        end
        close(output)
    elseif (option==2)
        Collected_Results_offset=Array{Array{UInt16}}(undef,no_of_chunks)
        Collected_Results_max_match_length=Array{Array{UInt16}}(undef,no_of_chunks)
        @threads for i in 1:no_of_chunks
            chunk_start_index=nextind(input,1,(fld(Length,no_of_chunks))*(i-1)+1)
            chunk_end_index=nextind(input,1,(fld(Length,no_of_chunks))*(i))
            if i==no_of_chunks
                chunk_end_index=nextind(input,1,Length-1)
            end
            Collected_Results_offset[i], Collected_Results_max_match_length[i], Collected_Results_following_character[i], Lengths_of_Compressed_Chunks[i] =Compress_GPU_Parallel_Search(input[chunk_start_index:chunk_end_index], option, search_buffer_length, look_ahead_buffer_length, chunk_start_index)
        end
        write(output,UInt8(2)) #to notify the decompressor of option used 
        write(output,UInt8(no_of_chunks))
        for i in 1:no_of_chunks
            write(output,UInt64(0))
            write(output,UInt64(Lengths_of_Compressed_Chunks[i]))
        end
        for i in 1:no_of_chunks
            for j in 1:Lengths_of_Compressed_Chunks[i]
                write(output,UInt16(Collected_Results_offset[i][j]))
                write(output,UInt16(Collected_Results_max_match_length[i][j]))
                write(output,Char(Collected_Results_following_character[i][j]))
            end
            current_position=position(output)
            seek(output,(((i-1)*16)+2))
            write(output,UInt64(current_position))
            seek(output,current_position)
        end
        close(output)
    else
        exit()
    end

end


function Compress_GPU_Parallel_Search(input_string, option_input, search_buffer_length, look_ahead_buffer_length, start_target)#(input,option)
    input=Array{Char}(undef,length(input_string))
    j=0
    for i in eachindex(input_string)
        j+=1
        input[j]=input_string[i]
    end
    input_d=CuArray{eltype(input)}(input)
    length_input_d=length(input_d)
    window_length=search_buffer_length+look_ahead_buffer_length

    match_data_zeros = Array{UInt64}(undef,window_length)
    fill!(match_data_zeros,0)


    option=UInt8(option_input)     #1 is for 12-bit, Max 4095  
    target=1    #position of character in string
    debug_filename="debug/Debug_findall_"*string(start_target)*".txt"
    debug_stream=open(debug_filename, "w")
    
    Results_following_character=Array{UInt64}(undef,length_input_d)
    Length_of_Compressed_Chunk=1

   if (option==1)
        Results_Upper_bits_of_Numbers=Array{UInt8}(undef,length_input_d)
        Results_offset_lower_8bits=Array{UInt8}(undef,length_input_d)
        Results_max_match_length_lower_8bits=Array{UInt8}(undef,length_input_d)
        Results_Upper_bits_of_Numbers[1]=UInt8(0)
        Results_offset_lower_8bits[1]=UInt8(0)
        Results_max_match_length_lower_8bits[1]=UInt8(0)
    elseif (option==2)
        Results_offset=Array{UInt16}(undef,length_input_d)
        Results_max_match_length=Array{UInt16}(undef,length_input_d)
        Results_offset[1]=UInt16(0)
        Results_max_match_length[1]=UInt16(0)
    end
    Results_following_character[1]=UInt64(input[target])
    # write(debug_stream,@sprintf "%d\n%-8d %-8d %s" option 0 0 input[target])

    target+=1
    current_search_buffer_length=1
    match_data_d=CuArray{eltype(match_data_zeros)}(match_data_zeros)

    @views while target <= length_input_d
        offset=0
        fill!(match_data_d,0)
        @cuda blocks=cld(current_search_buffer_length, MAX_THREADS_PER_BLOCK) threads=MAX_THREADS_PER_BLOCK searchKernel(input_d,length_input_d,target,current_search_buffer_length,window_length,match_data_d)
        max_match_length, max_match = findmax(match_data_d)
        if max_match_length>0
            offset=current_search_buffer_length-max_match+1
        end
        target+=max_match_length
        Length_of_Compressed_Chunk+=1
        if (option==1)
            offset_lower_8bits=UInt8(offset%256)
            offset_upper_4bits=fld(offset,256)

            max_match_length_lower_8bits=UInt8(max_match_length%256)
            max_match_length_upper_4bits=fld(max_match_length,256)*16
            Upper_bits_of_Numbers=UInt8(offset_upper_4bits+max_match_length_upper_4bits)

            Results_Upper_bits_of_Numbers[Length_of_Compressed_Chunk]=UInt8(Upper_bits_of_Numbers)
            Results_offset_lower_8bits[Length_of_Compressed_Chunk]=UInt8(offset_lower_8bits)
            Results_max_match_length_lower_8bits[Length_of_Compressed_Chunk]=UInt8(max_match_length_lower_8bits)
        elseif (option==2)
            Results_offset[Length_of_Compressed_Chunk]=UInt16(offset)
            Results_max_match_length[Length_of_Compressed_Chunk]=UInt16(max_match_length)
        end
        Results_following_character[Length_of_Compressed_Chunk]=UInt64(input[target])

        # write(debug_stream,@sprintf "\n%-8d %-8d %s  " offset max_match_length input[nextind(input,target_index,max_match_length)])
        # if max_match!=0
        #     if (offset-max_match_length+1)<0
        #         write(debug_stream,@sprintf "matched-\'%s\'" input[prevind(input,target_index,offset):nextind(input,target_index,max_match_length-offset-1)])#input[max_match:max_match+max_match_length-1])
        #     else
        #         write(debug_stream,@sprintf "matched-\'%s\'" input[prevind(input,target_index,offset):prevind(input,target_index,offset-max_match_length+1)])#input[max_match:max_match+max_match_length-1])
        #     end
        # end
        target+=1
        if (current_search_buffer_length<search_buffer_length)
            current_search_buffer_length+=max_match_length+1
            if(current_search_buffer_length>search_buffer_length)
                current_search_buffer_length=search_buffer_length
            end
        end
    end
    if (option==1)
        return Results_Upper_bits_of_Numbers, Results_offset_lower_8bits, Results_max_match_length_lower_8bits, Results_following_character, Length_of_Compressed_Chunk
    elseif (option==2)
        return Results_offset, Results_max_match_length, Results_following_character, Length_of_Compressed_Chunk
    end
    close(debug_stream)
end
println("Parallel CPU and GPU implementation search_buffer_length-4075")
    # CUDA.@time Compress_Parallel_Divided_Input_GPU_Search(1,4075)
    # CUDA.@time Compress_Parallel_Divided_Input_GPU_Search(1,4075)
    # CUDA.@time Compress_Parallel_Divided_Input_GPU_Search(1,4075)
    # println("\nParallel CPU and GPU implementation search_buffer_length-65000")
    CUDA.@time Compress_Parallel_Divided_Input_GPU_Search(2,65000)
    CUDA.@time Compress_Parallel_Divided_Input_GPU_Search(2,65000)
    CUDA.@time Compress_Parallel_Divided_Input_GPU_Search(2,65000)
    # CUDA.@time Compress_Parallel_Divided_Input_GPU_Search(2,65000)
GC.gc(true)
