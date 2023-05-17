write_stream=open("Uncompressed.txt", "w")
# read_stream=open("Compressed_eachindex.txt", "r")
read_stream=open("Compressed\\Compressed_Compress_Parallel_Search1_findmax.txt", "r")
output=""
char_being_processed=1
option=read(read_stream,UInt8)
char_being_processed_index=1

@views while(!eof(read_stream))
    if option==1
        Upper_bits_of_Numbers=read(read_stream,UInt8)
        offset_upper_4bits=Upper_bits_of_Numbers%16
        max_match_length_upper_4bits=fld(Upper_bits_of_Numbers,16)

        offset_lower_8bits=read(read_stream,UInt8)
        max_match_length_lower_8bits=read(read_stream,UInt8)

        offset=Int64(offset_upper_4bits*256+offset_lower_8bits)
        length_of_match=Int64(max_match_length_upper_4bits*256+max_match_length_lower_8bits)

    elseif option==2
        offset=Int64(read(read_stream,UInt16))
        length_of_match=Int64(read(read_stream,UInt16))
    end

    if offset!=0
        if (offset-length_of_match+1)>0
            global output=output*(output[prevind(output,char_being_processed_index,offset):prevind(output,char_being_processed_index,offset-length_of_match+1)])
        else
            global output=output*(output[prevind(output,char_being_processed_index,offset):prevind(output,char_being_processed_index)])
            temp_index=char_being_processed_index
            for i in 1:length_of_match-offset
                global output=output*(output[temp_index])
                temp_index=(nextind(output,temp_index))
            end
        end
        char_being_processed+=length_of_match
        char_being_processed_index=nextind(output,char_being_processed_index,length_of_match)
    end

    character=read(read_stream,Char)    
    global output=output*character
    global char_being_processed_index=nextind(output,char_being_processed_index,1)
    global char_being_processed+=1
end
write(write_stream,output)
close(write_stream)
