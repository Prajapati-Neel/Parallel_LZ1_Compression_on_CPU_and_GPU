write_stream=open("Uncompressed.txt", "w")
read_stream=open("compressed.txt", "r")
output=""
char_being_processed=1
option=read(read_stream,UInt8)

@views while(!eof(read_stream))
    if option==1
        Upper_bits_of_Numbers=read(read_stream,UInt8)
        offset_upper_4bits=Upper_bits_of_Numbers%16
        max_match_length_upper_4bits=fld(Upper_bits_of_Numbers,16)

        offset_lower_8bits=read(read_stream,UInt8)
        max_match_length_lower_8bits=read(read_stream,UInt8)

        offset=offset_upper_4bits*256+offset_lower_8bits
        length_of_match=max_match_length_upper_4bits*256+max_match_length_lower_8bits

    elseif option==2
        offset=read(read_stream,UInt16)
        length_of_match=read(read_stream,UInt16)
    end
    character=read(read_stream,Char)    

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
