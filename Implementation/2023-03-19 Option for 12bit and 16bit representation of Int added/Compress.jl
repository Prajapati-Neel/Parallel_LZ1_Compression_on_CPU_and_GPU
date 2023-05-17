# stream=open("my_file.txt", "r")
# stream=open("my_file1.txt", "w")
# write(stream,input)
# close(stream)
using Printf
input=read("my_file.txt",String)

option=UInt8(1)     #1 is for 12-bit, Max 4095  
# option=UInt8(2)     #2 is for 16-bit, Max 65535
search_buffer_length=4075
look_ahead_buffer_length=20


target=1;

isascii(input)
Length=length(input)
if(Length<200)
    exit()
end

stream1=open("Compressed.txt", "w")
stream2=open("Debug.txt", "w")


if !((option==1 && (search_buffer_length+look_ahead_buffer_length)<=4095)||(option==2 && (search_buffer_length+look_ahead_buffer_length)<=65535))
    println("make sure the search_buffer_length and look_ahead_buffer_length are within limits")
    exit()
end
if (option==1)
    write(stream1,UInt8(1))

    write(stream1,UInt8(0))
    write(stream1,UInt8(0))
    write(stream1,UInt8(0))
    write(stream1,input[target])
elseif (option==2)
    write(stream1,UInt8(2))

    write(stream1,UInt16(0))
    write(stream1,UInt16(0))
    write(stream1,input[target])
end

write(stream2,@sprintf "\n%-8d %-8d %s" 0 0 input[target])

target+=1

current_search_buffer_length=1

while target <= Length
    max_match= target
    max_match_length=0
    c=input[target]
    for i in target-current_search_buffer_length:target-1
        if max_match_length==search_buffer_length+look_ahead_buffer_length
            break
        end
        match_length=0
        while ((match_length<search_buffer_length+look_ahead_buffer_length) && (match_length+target<length(input)) && (input[i+match_length]==input[target+match_length]))
            match_length+=1
        end
        if match_length>max_match_length
        max_match=i
        max_match_length=match_length
        end
        if max_match_length==search_buffer_length+look_ahead_buffer_length
            break
        end
    end
    offset=target-max_match

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
write(stream1,input[target+max_match_length])

# write(stream1,@sprintf "%c%c%c" Char[(target-max_match)] Char[max_match_length] input[target+max_match_length])
    
    write(stream2,@sprintf "\n%-8d %-8d %s  " (target-max_match) max_match_length input[target+max_match_length])
    if max_match!=target
        write(stream2,@sprintf "matched-\'%s\'" input[max_match:max_match+max_match_length-1])
    end
    global target+=max_match_length+1
    if (current_search_buffer_length<search_buffer_length)
        global current_search_buffer_length+=max_match_length+1
        if(current_search_buffer_length>search_buffer_length)
            current_search_buffer_length=search_buffer_length
        end
    end
end
close(stream1)
close(stream2)