using Base.Threads, BenchmarkTools

function Uncompress_Parallel_Divided_Input()
    write_stream=open("Uncompressed.txt", "w")
    input_file_name="Compressed\\Compressed_Parallel_Divided_Input1.txt"
    read_stream=open(input_file_name, "r")
    option=read(read_stream,UInt8)
    no_of_chunks=read(read_stream,UInt8)
    Output_strings=Array{String}(undef,no_of_chunks)
    positions_in_file=Array{UInt64}(undef,no_of_chunks+1)
    Lengths_of_Compressed_Chunks=Array{UInt64}(undef,no_of_chunks)

    for i in 1:no_of_chunks
        positions_in_file[i+1]=read(read_stream,UInt64)
        Lengths_of_Compressed_Chunks[i]=read(read_stream,UInt64)    
        if i==no_of_chunks
            positions_in_file[1]=position(read_stream)
        end
    end
    close(read_stream)
    @threads for i in 1:no_of_chunks
        Output_strings[i]=Uncompress(option, positions_in_file[i], Lengths_of_Compressed_Chunks[i],input_file_name)
    end
    for i in 1:no_of_chunks
        write(write_stream,Output_strings[i])
    end
    close(write_stream)

end

function Uncompress(option_input, position_in_file, Length_of_Compressed_Chunk,input_file_name)
    local_read_stream=open(input_file_name, "r")
    seek(local_read_stream,position_in_file)
    output=""
    char_being_processed=1
    char_being_processed_index=1
    option=option_input
    @views for j in 1:Length_of_Compressed_Chunk
        if option==1
            Upper_bits_of_Numbers=read(local_read_stream,UInt8)
            offset_upper_4bits=Upper_bits_of_Numbers%16
            max_match_length_upper_4bits=fld(Upper_bits_of_Numbers,16)

            offset_lower_8bits=read(local_read_stream,UInt8)
            max_match_length_lower_8bits=read(local_read_stream,UInt8)

            offset=Int64(offset_upper_4bits*256+offset_lower_8bits)
            length_of_match=Int64(max_match_length_upper_4bits*256+max_match_length_lower_8bits)

        elseif option==2
            offset=Int64(read(local_read_stream,UInt16))
            length_of_match=Int64(read(local_read_stream,UInt16))
        end
        if offset!=0
            if (offset-length_of_match+1)>0
                output=output*(output[prevind(output,char_being_processed_index,offset):prevind(output,char_being_processed_index,offset-length_of_match+1)])
            else
                output=output*(output[prevind(output,char_being_processed_index,offset):prevind(output,char_being_processed_index)])
                temp_index=char_being_processed_index
                for i in 1:length_of_match-offset
                    output=output*(output[temp_index])
                    temp_index=(nextind(output,temp_index))
                end
            end
            char_being_processed+=length_of_match
            char_being_processed_index=nextind(output,char_being_processed_index,length_of_match)
        end

        character=read(local_read_stream,Char)    
        output=output*character
        char_being_processed_index=nextind(output,char_being_processed_index,1)
        char_being_processed+=1
    end
    return output
    close(local_read_stream)
end
Uncompress_Parallel_Divided_Input()

