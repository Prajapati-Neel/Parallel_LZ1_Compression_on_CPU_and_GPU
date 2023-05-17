# stream=open("my_file.txt", "r")
# stream=open("my_file1.txt", "w")
# write(stream,input)
# close(stream)
using Printf,BenchmarkTools
input=read("my_file.txt",String)
search_buffer_length=128
look_ahead_buffer_length=128
target=1;

Length=length(input)
if(Length<200)
    exit
end

print(0,0,input[target])
target+=1

current_search_buffer_length=1
while target <= Length
    max_match=  target
    max_match_length=1
    first_match_array=findall(c -> c == input[target], @view input[target-current_search_buffer_length:target-1])
    # print(first_match_array)
    for i in first_match_array
        i+=target-current_search_buffer_length
        match_length=1
        while ((match_length<search_buffer_length+look_ahead_buffer_length) && (match_length+target<=length(input)) && (input[i+match_length]==input[target+match_length]))
            match_length+=1
        end
        if match_length>max_match_length
        max_match=i
        max_match_length=match_length
        end
    end
    
    @printf "\n%-8d %-8d" (target-max_match) max_match_length
    print(input[target])
    # print("  ", target,"    ",max_match)
    global target+=max_match_length
    if (current_search_buffer_length<search_buffer_length)
        global current_search_buffer_length+=max_match_length
        if(current_search_buffer_length>64)
            current_search_buffer_length=64
        end
    end
end
