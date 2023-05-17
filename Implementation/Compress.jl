# stream=open("my_file.txt", "r")
# stream=open("my_file1.txt", "w")
# write(stream,input)
# close(stream)
using Printf, BenchmarkTools

# if(Length<200)
#     exit()
# end

function Compress_eachindex(option_input,search_buffer_length)#(input,option)
    input=read("Input_for_Compression.txt",String)
    option=UInt8(option_input)     #1 is for 12-bit, Max 4095  
    # option=UInt8(2)     #2 is for 16-bit, Max 65535
    look_ahead_buffer_length=20
    Length=length(input)
    target=1    #position of character in string
    target_index=1  #index of character in string

    stream1=open("Compressed\\Compressed_eachindex.txt", "w")
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
    target_index=nextind(input,1)
    current_search_buffer_length=1

    @views while target <= Length
        max_match= 0
        max_match_length=0
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
        target+=max_match_length+1
        target_index=nextind(input,target_index,max_match_length+1)
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


function Compress_findall(option_input,search_buffer_length)#(input,option)
    input=read("Input_for_Compression - 45.4KB.txt",String)
    option=UInt8(option_input)     #1 is for 12-bit, Max 4095  
    # option=UInt8(2)     #2 is for 16-bit, Max 65535
    # search_buffer_length=4075
    look_ahead_buffer_length=20
    Length=length(input)
    target=1    #position of character in string
    target_index=1  #index of character in string

    stream1=open("Compressed\\Compressed_findall.txt", "w")
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
    target_index=nextind(input,1)
    current_search_buffer_length=1

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
        target+=max_match_length+1
        target_index=nextind(input,target_index,max_match_length+1)
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

function Compress_Char_Array(option_input,search_buffer_length)#(input,option)
    input_string=read("Input_for_Compression.txt",String)
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



    target=1    #position of character in string

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
    current_search_buffer_length=1

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
            current_search_buffer_length+=max_match_length+1
            if(current_search_buffer_length>search_buffer_length)
                current_search_buffer_length=search_buffer_length
            end
        end
    end
    close(stream1)
    close(stream2)
end
# Compress_findall(1)
@btime Compress_Char_Array(1,4075)
@btime Compress_Char_Array(2,65000)
# @btime Compress_eachindex(1,4075)
# @btime Compress_eachindex(2,65000)
println("Char array")
# @btime Compress_findall(1,4075)
# @btime Compress_findall(2,65000)
# @btime Compress_findall(2)
GC.gc(true)
