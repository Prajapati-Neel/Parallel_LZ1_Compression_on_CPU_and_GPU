write_stream=open("Uncompressed.txt", "w")
input=read("compressed.txt",String)
output=""
char_being_processed=1
@views for i in 1:3:length(input)
    offset=Int(input[i])
    length_of_match=Int(input[i+1])
    character=input[i+2]    
    if offset!=0
        for j in 1:length_of_match         
            global output=output*output[char_being_processed-offset]
            global char_being_processed+=1
        end
    end
    global output=output*character
    global char_being_processed+=1
end
write(write_stream,output)
close(write_stream)
