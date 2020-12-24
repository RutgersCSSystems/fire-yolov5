#include "ngram.hpp"

int ngram::insert_to_ngram(struct pos_bytes access)
{
    /*
     * The user will call insert_to_ngram everytime there is an access.
     * Depending on the length of GRAMS, it will insert in MOM
     */
    current_stream.push_back(access);

    if(current_stream.size() > GRAMS) //will insert to MOM now
    {
        std::string first_key = convert_to_string(current_stream, 0, GRAMS); //key to top lvl map
        std::cout << "first_key = " << first_key << std::endl;

        std::string second_key = convert_to_string(current_stream, GRAMS, 1); //Key to second map
        std::cout << "second_key = " << second_key << std::endl;


        auto first_key_loc = past_freq.find(first_key);

        if(first_key_loc == past_freq.end()) //Did not find the first key
        {
            std::cout << "NOT found first key " << first_key << std::endl;
            std::unordered_map<std::string, int> sec_map;
            sec_map[second_key] = 1;
            past_freq[first_key] = sec_map;
        }
        else //Did find the first key
        {
            std::cout << "found first key " << first_key << std::endl;
            auto second_map = first_key_loc->second;
            auto second_key_loc = second_map.find(second_key);
            if(second_key_loc == second_map.end()) //Did not find the second key
            {
                std::cout << "NOT found second key " << second_key << std::endl;
                //second_map[second_key] = 1;
                first_key_loc->second[second_key] = 1;
            }
            else
            {
                std::cout << "found second key " << second_key << std::endl;
                //second_map[second_key] += 1;
                first_key_loc->second[second_key] += 1;
            }
        }
        current_stream.pop_front();
    }
}

std::string ngram::get_max_freq_access(std::string first_key) //ret access with max freq
{
    std::string max_freq_access = "";

    auto first_key_loc = past_freq.find(first_key);

    if(first_key_loc == past_freq.end()) //did not find the input first key
        return max_freq_access;
    else
    {
        auto second_map = first_key_loc->second;
        int max_val = 0;

        auto sec_iter = second_map.begin();
        while(sec_iter != second_map.end())
        {
            if(sec_iter->second > max_val)
            {
                max_val = sec_iter->second;
                max_freq_access = sec_iter->first;
            }
            *sec_iter++;
        }
    }

    return max_freq_access;
}

void ngram::print_ngram()
{
    std::cout << "Printing the Ngram\n"; 

    auto first_iter = past_freq.begin();

    while(first_iter != past_freq.end())
    {
        std::cout << "Req String = " << first_iter->first << std::endl;

        auto second_iter = first_iter->second.begin();
        while(second_iter != first_iter->second.end())
        {
            std:: cout << second_iter->first << ": " << second_iter->second << std::endl;
            *second_iter ++;
        }
        *first_iter ++;
    }
    return;
}

std::string convert_to_string(std::deque<struct pos_bytes> stream, int start, int length)
{
    std::string ret;

    if(stream.size() < length+start)
        return ""; //Error - shouldnt have happened

    auto dqiter = stream.begin() + start;

    for(int i=0; i<length; i++)
    {
        if(dqiter == stream.end())
            break;
        
        ret += std::to_string(dqiter->fd) + ",";
        ret += std::to_string(dqiter->pos) + ",";
        ret += std::to_string(dqiter->bytes) + "+";

        *dqiter++;
    }
    return ret;
}

/*
std::deque<struct pos_bytes> *string_to_deque(std::string input)
{   
    std::deque<struct pos_bytes> ret;

    if(input == NULL || input.size() <=0)
        return NULL;
}
*/
