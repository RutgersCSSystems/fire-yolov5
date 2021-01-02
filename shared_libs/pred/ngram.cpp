#include "ngram.hpp"

int ngram::insert_to_ngram(struct pos_bytes access)
{
    /*
     * The user will call insert_to_ngram everytime there is an access.
     * Depending on the length of GRAMS, it will insert in MOM
     */
    current_stream.push_back(access);
    all_accesses.insert(convert_to_string(current_stream, current_stream.size()-1, 1)); //latest addition to set

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

    std::cout << "set content " << all_accesses.size()<< std::endl;
    for(auto i : all_accesses) {
        std::cout << i << "- " ;
        //std::cout << i << "-" << std::hash<std::string>()(i) << " ";
    }
    std::cout << std::endl;
    return;
}

std::multimap<float, std::string> ngram::gnn_recursive(std::multimap<float, std::string> map, int n)
{
    if(n==0)
        return map;

    std::multimap<float, std::string> new_map;

    for(auto i : map)
    {
        //i.first is the confidence in this value
        //i.second is the access(fd:offset:bytes) string of length <= n
        //query the deque and insert all the new strings
        auto deq = string_to_deque(i.second);
        //std::string first_key = 
    }

    return gnn_recursive(new_map, --n);
}

//returns map <Priority, Access string> 
//larger is greater probability
std::multimap<float, std::string> ngram::get_next_n_accesses(int n)
{
    std::multimap<float, std::string> ret;

    if(current_stream.size() <= GRAMS)
        return ret;

    //get the last stream of GRAMS access
    std::string latest_access_stream = convert_to_string(current_stream, current_stream.size()-GRAMS, GRAMS); //last GRAMS access

    ret.insert({1, latest_access_stream});
    return gnn_recursive(ret, n);

    //query MOM to get all the accesses - use recursion
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

std::deque<struct pos_bytes> string_to_deque(std::string input)
{   
    std::deque<struct pos_bytes> ret;
    struct pos_bytes entry;

    /*
       if(input.size() <= 0)
       return NULL;
       */

    std::vector<std::string> tokens;
    std::stringstream check1(input);
    std::string intermediate;

    while(getline(check1, intermediate, '+'))
    {
        tokens.push_back(intermediate);
    }

    for(int i=0; i<tokens.size(); i++)
    {
        std::stringstream check2(tokens[i]);
        getline(check2, intermediate, ',');
        entry.fd = stoi(intermediate);

        getline(check2, intermediate, ',');
        entry.pos = stoi(intermediate);

        getline(check2, intermediate, ',');
        entry.bytes = stoi(intermediate);

        ret.push_back(entry);
    }

    return ret;
}
