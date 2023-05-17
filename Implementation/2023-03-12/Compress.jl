# stream=open("my_file.txt", "r")
# stream=open("my_file1.txt", "w")
# write(stream,input)
# close(stream)
using Printf
input=read("my_file.txt",String)
search_buffer_length=64
look_ahead_buffer_length=64
target=1;
isascii(input)
Length=length(input)
if(Length<200)
    exit
end
stream1=open("Compressed.txt", "w")
stream2=open("Debug.txt", "w")

write(stream1,@sprintf "%c%c%c" 0 0 input[target])
write(stream2,@sprintf "\n%-8d %-8d %s" 0 0 input[target])
# print(0,0,input[target])
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

    write(stream1,@sprintf "%c%c%c" Char[(target-max_match)] Char[max_match_length] input[target+max_match_length])
    
    # write(stream1,@sprintf "\n%-8d %-8d %s  " (target-max_match) max_match_length input[target+max_match_length])
    write(stream2,@sprintf "\n%-8d %-8d %s  " (target-max_match) max_match_length input[target+max_match_length])
    if max_match!=target
        write(stream2,@sprintf "matched-\'%s\'" input[max_match:max_match+max_match_length-1])
    end
    global target+=max_match_length+1
    if (current_search_buffer_length<search_buffer_length)
        global current_search_buffer_length+=max_match_length+1
        if(current_search_buffer_length>64)
            current_search_buffer_length=64
        end
    end
end
close(stream1)
close(stream2)