# stream=open("my_file.txt", "r")
# stream=open("my_file1.txt", "w")
# write(stream,input)
# close(stream)
using Printf
input=read("my_file.txt",String)

option=UInt8(2)     #1 is for 12-bit, Max 4095  
# option=UInt8(2)     #2 is for 16-bit, Max 65535
search_buffer_length=4075
look_ahead_buffer_length=20


target=1    #position of character in string
target_index=1  #index of character in string

# isascii(input)
Length=length(input)
if(Length<200)
    exit()
end

stream1=open("Compressed.txt", "w")
stream2=open("Debug.txt", "w")
stream3=open("Compare.txt", "w")


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
end

write(stream2,@sprintf "\n%-8d %-8d %s" 0 0 input[target_index])

target+=1
target_index=nextind(input,1)

current_search_buffer_length=1

@views while target <= Length
    max_match= 0
    max_match_length=0
    c=input[target_index]
    # println(prevind(input,target_index,target-current_search_buffer_length))
    i=current_search_buffer_length
    # println([prevind(input,target_index,current_search_buffer_length):prevind(input,target_index)])
    eachindex_correction=prevind(input,target_index,current_search_buffer_length)-1 
    for index in eachindex(input[prevind(input,target_index,current_search_buffer_length):prevind(input,target_index)])
        if max_match_length==search_buffer_length+look_ahead_buffer_length
            break
        end
        match_length=0
        index+=eachindex_correction #eachindex() always returns an iterator that starts from 1 to correct this the index of first character of range prevind(input,target_index,current_search_buffer_length) has been added.
        # write(stream3,@sprintf "%-8c %-8c\n" input[nextind(input,index,match_length)] input[nextind(input,target_index,match_length)])
        # write(stream3,@sprintf "%-8d %-8d\n" nextind(input,index,match_length) nextind(input,target_index,match_length))
        # write(stream3,@sprintf "%-8d\n" index)
        while ((match_length<search_buffer_length+look_ahead_buffer_length) && (match_length+target<length(input)) &&(input[nextind(input,index,match_length)]==input[nextind(input,target_index,match_length)])) 
        match_length+=1
        end
        if match_length>max_match_length
            max_match=i
            max_match_length=match_length
            if ((current_search_buffer_length>1000))
                # write(stream3,@sprintf "%-8d %-8d\n" max_match max_match_length)
            end
        end
        if max_match_length==search_buffer_length+look_ahead_buffer_length
            break
        end
        # write(stream3,@sprintf "%-8d %-8d\n" i max_match_length)
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

    # write(stream1,@sprintf "%c%c%c" Char[(target-max_match)] Char[max_match_length] input[target+max_match_length])
    # write(stream3,@sprintf "%-8d %-8d\n" offset max_match_length)

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
close(stream3)
GC.gc(true)
