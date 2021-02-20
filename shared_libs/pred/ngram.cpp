#include "ngram.hpp"

int ngram::insert_to_ngram(struct pos_bytes access)
{
     debug_print("access fd: %d\n", access.fd);
    /*
     * The user will call insert_to_ngram everytime there is an access.
     * Depending on the length of GRAMS, it will insert in MOM
     */
    current_stream.push_back(access);
    all_accesses.insert(deque_to_string(current_stream, current_stream.size()-1, 1)); //latest addition to set

    if(current_stream.size() > GRAMS) //will insert to MOM now
    {
        std::string first_key = deque_to_string(current_stream, 0, GRAMS); //key to top lvl map

        std::string second_key = deque_to_string(current_stream, GRAMS, 1); //Key to second map


        auto first_key_loc = past_freq.find(first_key);

        if(first_key_loc == past_freq.end()) //Did not find the first key
        {
            std::unordered_map<std::string, int> sec_map;
            sec_map[second_key] = 1;
            past_freq[first_key] = sec_map;
        }
        else //Did find the first key
        {
            auto second_map = first_key_loc->second;
            auto second_key_loc = second_map.find(second_key);
            if(second_key_loc == second_map.end()) //Did not find the second key
            {
                //second_map[second_key] = 1;
                first_key_loc->second[second_key] = 1;
            }
            else
            {
                //second_map[second_key] += 1;
                first_key_loc->second[second_key] += 1;
            }
        }
        current_stream.pop_front();
    }
}

//Remove any keys with this fd and
//any values with this fd
void ngram::remove_from_ngram(int fd)
{
    if(past_freq.size() == 0)
        return;
    auto iter = past_freq.begin();
    while(iter != past_freq.end())
    {
        if(fd_in_string(iter->first, fd))
        {
            iter = past_freq.erase(iter);
            continue;
        }
        //check if any of the values has a 
        auto jter = iter->second.begin();
        while(jter != iter->second.end())
        {
            if(fd_in_string(jter->first, fd))
            {
                jter = iter->second.erase(jter);
            }
            else
                jter ++;
        }
        iter++;
    }


    //If the current_stream has the element delete current stream
    for(auto cstream : current_stream)
    {
        if(cstream.fd == fd)
        {
            current_stream.clear();
            break;
        }
    }

    //Remove all elements from set with fd
    auto setelem = all_accesses.begin();
    while(setelem != all_accesses.end())
    {
        if(fd_in_string(*setelem, fd))
        {
            setelem = all_accesses.erase(setelem);
        }
        else
            setelem ++;
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

std::multimap<float, std::string> ngram::__gnn_recursive(std::multimap<float, std::string> map, int n)
{
    if(n==0 || map.size() == 0)
        return map;

    std::multimap<float, std::string> new_map;

    for(auto i : map)
    {
        //i.first is the confidence in this value
        //i.second is the access(fd:offset:bytes) string of length <= n
        //query the deque and insert all the new strings
        auto deq = string_to_deque(i.second);
        std::string first_key = deque_to_string(deq, deq.size()-GRAMS, GRAMS);

        //query MOM to see if there is a prior entry
        auto first_key_loc = past_freq.find(first_key);

        if(first_key_loc == past_freq.end()) //did not find the key
        {
            new_map.insert({i.first, i.second});
        }
        else //found the entry in past_freq
        {
            for(auto j : past_freq[first_key])
            {
                //j.first -> single access string
                //j.second -> access freq
                // new freq = i.first + n * j.second
                //
                new_map.insert({i.first+n*j.second, i.second+j.first});
            }
        }
    }

    return __gnn_recursive(new_map, --n);
}

//returns map <Priority, Access string> 
//larger is greater probability
std::multimap<float, std::string> ngram::get_next_n_accesses(int n)
{
    std::multimap<float, std::string> ret;

    if(current_stream.size() < GRAMS)
    {
        return ret;
    }

    //get the last stream of GRAMS access
    std::string latest_access_stream = deque_to_string(current_stream, current_stream.size()-GRAMS, GRAMS); //last GRAMS access

    ret.insert({1, latest_access_stream});
    return __gnn_recursive(ret, n);
}

std::deque<struct pos_bytes> ngram::get_notneeded(std::multimap<float, std::string> next_n_accesses)
{
    std::set<std::string> ret;

    std::string all_needed;

    for(auto i : next_n_accesses)
    {
        all_needed += i.second;
    }

    std::set<std::string> all_needed_set = string_to_set(all_needed);

    std::set_difference(all_accesses.begin(), all_accesses.end(),
            all_needed_set.begin(), all_needed_set.end(), 
            std::inserter(ret, ret.end()));

    all_needed = ""; //reset for deque
    for(auto i : ret)
    {
        all_needed += i;
    }

    auto ret_dq = string_to_deque(all_needed);
    return ret_dq;
}

std::string deque_to_string(std::deque<struct pos_bytes> stream, int start, int length)
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

//TODO: Try doing this using REGEX
//returns true if fd is found in access string
bool fd_in_string(std::string input, int fd)
{
    if(input.size() <= 0)
        return false;

    std::stringstream check1(input);
    std::string intermediate, inter1;
    while(getline(check1, intermediate, '+'))
    {
        std::stringstream check2(intermediate);
        getline(check2, inter1, ',');
        if(stoi(inter1) == fd)
            return true;
    }

    return false;
}


std::set<std::string> string_to_set(std::string input)
{
    std::set<std::string> ret;

    std::stringstream check1(input);
    std::string intermediate;

    while(getline(check1, intermediate, '+'))
    {
        ret.insert(intermediate+'+');
    }
    return ret;
}
