using Printf, BenchmarkTools
function Compress_Char_Array(option_input,search_buffer_length)#(input,option)
    input_string=read("Input_for_Compression - 180KB.txt",String)
    Length=length(input_string)

    input=Array{Char}(undef,Length)
    j=0
    for i in eachindex(input_string)
        j+=1
        input[j]=input_string[i]
    end

    # search_buffer_length=4075
    look_ahead_buffer_length=20
    window_length=search_buffer_length+look_ahead_buffer_length

    global target=1    #position of character in string

    option=UInt8(option_input)     #1 is for 12-bit, Max 4095  
    # option=UInt8(2)     #2 is for 16-bit, Max 65535

    if(option_input==1)
        stream1=open("Compressed\\Compressed1.txt", "w")
    elseif(option_input==2) 
        stream1=open("Compressed\\Compressed2.txt", "w")
    end
    stream2=open("Debug_Compress", "w")


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
    write(stream2,@sprintf "%d\n%-8d %-8d %s" option 0 0 input[target])

    target+=1
    global current_search_buffer_length=1

    while target <= Length
        max_match_length=0
        offset=0
         for i in target-current_search_buffer_length:target-1
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
                offset=target-i
                max_match_length=match_length
            end
            if max_match_length==window_length
                break
            end
        end
        
        # max_match_length, max_match = findmax(match_data_d)
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
@btime Compress_Char_Array(1,4075)
@btime Compress_Char_Array(2,65000)
