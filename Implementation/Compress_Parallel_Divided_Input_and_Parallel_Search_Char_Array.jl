using Printf, BenchmarkTools
using Base.Threads

function Compress_Parallel_Divided_Input_and_Parallel_Search_Char_Array(option_input,search_buffer_length)
    input=read("Input_for_Compression.txt",String)
    output=open("Compressed\\Compressed_Parallel_Divided_Input1.txt", "w")

    # if (option_input==1)
    #     output=open("Compressed\\Compressed_Parallel_Divided_Input1.txt", "w")
    # elseif (option_input==2) 
    #     output=open("Compressed\\Compressed_Parallel_Divided_Input2.txt", "w")
    # end
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
            # tasks[i] = Threads.@spawn Collected_Results_Upper_bits_of_Numbers[i], Collected_Results_offset_lower_8bits[i], Collected_Results_max_match_length_lower_8bits[i], Collected_Results_following_character[i], Lengths_of_Compressed_Chunks[i] = Compress_Parallel_Search_Char_Array(input[chunk_start_index:chunk_end_index], option, search_buffer_length, look_ahead_buffer_length, chunk_start_index)
            Collected_Results_Upper_bits_of_Numbers[i], Collected_Results_offset_lower_8bits[i], Collected_Results_max_match_length_lower_8bits[i], Collected_Results_following_character[i], Lengths_of_Compressed_Chunks[i] = Compress_Parallel_Search_Char_Array(input[chunk_start_index:chunk_end_index], option, search_buffer_length, look_ahead_buffer_length, chunk_start_index)
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
            Collected_Results_offset[i], Collected_Results_max_match_length[i], Collected_Results_following_character[i], Lengths_of_Compressed_Chunks[i] =Compress_Parallel_Search_Char_Array(input[chunk_start_index:chunk_end_index], option, search_buffer_length, look_ahead_buffer_length, chunk_start_index)
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


function Compress_Parallel_Search_Char_Array(input_string, option, search_buffer_length, look_ahead_buffer_length, start_target)#(input,option)
    lock1 = SpinLock()
    window_length=search_buffer_length+look_ahead_buffer_length

    Length=length(input_string)
    input=Array{Char}(undef,Length)
    j=0
    for i in eachindex(input_string)
        j+=1
        input[j]=input_string[i]
    end

    target=1    #position of character in string
    debug_filename="debug/Debug_findall_"*string(start_target)*".txt"
    debug_stream=open(debug_filename, "w")
    
    Results_following_character=Array{UInt64}(undef,Length)
    Length_of_Compressed_Chunk=1

   if (option==1)
        Results_Upper_bits_of_Numbers=Array{UInt8}(undef,Length)
        Results_offset_lower_8bits=Array{UInt8}(undef,Length)
        Results_max_match_length_lower_8bits=Array{UInt8}(undef,Length)
        Results_Upper_bits_of_Numbers[1]=UInt8(0)
        Results_offset_lower_8bits[1]=UInt8(0)
        Results_max_match_length_lower_8bits[1]=UInt8(0)
    elseif (option==2)
        Results_offset=Array{UInt16}(undef,Length)
        Results_max_match_length=Array{UInt16}(undef,Length)
        Results_offset[1]=UInt16(0)
        Results_max_match_length[1]=UInt16(0)
    end
    Results_following_character[1]=UInt64(input[target])
    write(debug_stream,@sprintf "%d\n%-8d %-8d %s" option 0 0 input[target])

    target+=1
    current_search_buffer_length=1

    @views while target <= Length
        max_match_length=0
        offset=0
        @threads for i in target-current_search_buffer_length:target-1
            match_length=0
            if input[i]==input[target]
                current_char=i
                temp_target=target
                while (match_length+target<Length && match_length<window_length && input[current_char]==input[temp_target])
                    match_length+=1
                    current_char+=1
                    temp_target+=1
                end
            end
            if match_length>max_match_length
                lock(lock1) do
                    if match_length>max_match_length
                        offset=target-i
                        max_match_length=match_length
                    end
                end
            end
        end
        Length_of_Compressed_Chunk+=1
        target+=max_match_length
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

        write(debug_stream,@sprintf "\n%-8d %-8d %s  " offset max_match_length input[target])
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
    @btime Compress_Parallel_Divided_Input_and_Parallel_Search_Char_Array(1,4075)
    @btime Compress_Parallel_Divided_Input_and_Parallel_Search_Char_Array(2,65000)
GC.gc(true)
