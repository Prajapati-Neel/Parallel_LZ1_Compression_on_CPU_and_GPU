using BenchmarkTools
using Printf

function testing_arrays(search_string)
    input_string=read("Input_for_Compression.txt",String)
    length_input=length(input_string)
    input=Array{Char}(undef,length_input)
    j=0
    for i in eachindex(input_string)
        j+=1
        input[j]=input_string[i]
    end
    length_search=length(search_string)
    search=Array{Char}(undef,length_search)
    j=0
    for i in eachindex(search_string)
        j+=1
        search[j]=search_string[i]
    end
    max_location=0
    max_length=0
    for i in 1:length_input
        j=1
        x=i
        while(j<length_search && x<length_input && input[x]==search[j])
            j+=1
            x+=1
        end
        if max_length<j-1
            max_location=i
            max_length=j-1
        end
    end
    # for i in max_location:max_location+max_length
    #     print(input[i])
    # end
    # println(max_location)
end

function testing_strings(search_string)
    input_string=read("Input_for_Compression.txt",String)
    length_input=sizeof(input_string)

    length_search=length(search_string)

    max_location=0
    max_length=0
    matches=findall(c -> c == search_string[1], input_string) 
    for index in matches
        j=1
        x=nextind(input_string,index,1)
        while(j<length_search && x<=length_input && input_string[x]==search_string[nextind(search_string,1,j)])
            j+=1
            x=nextind(input_string,x,1)
            
        end
        if max_length<j
            max_location=length(input_string[1:index])
            max_length=j
        end
    end
    # print(input_string[nextind(input_string, 1, max_location-1):nextind(input_string, 1, max_location+max_length-2)])
    # println(max_location)
 
end
search_string="Copyright © 2012, Oracle and/or its affiliates. All rights reserved. Oracle and Java are registered trademarks of Oracle and/or its affiliates. Other names may be trademarks of their respective owners. 113940"

@btime testing_arrays(search_string)
@btime testing_strings(search_string)