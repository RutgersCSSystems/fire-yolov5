#include "sequential.hpp"


void sequential::insert(struct pos_bytes access)
{
    if(!exists(access.fd))
    {
        init_stride(access.fd);
    }
    current_stream[access.fd].push_back(access);

    update_stride(access.fd);

}

void sequential::remove(int fd)
{
    strides.erase(fd);
    current_stream.erase(fd);
    return;
}

void sequential::print_all_strides()
{
    for(auto a : strides)
    {
        std::cout << get_stride(a.first) << std::endl;
    }
}

off_t sequential::get_stride(int fd)
{
    if(exists(fd))
        return strides[fd].stride;
}

void sequential::init_stride(int fd)
{
        strides[fd].stride = -1;
        return;
}

void sequential::update_stride(int fd)
{
    if(exists(fd) && current_stream[fd].size() > LENGTH)
    {
        int this_stride;
        
        current_stream[fd].pop_front();
    }
}

bool sequential::exists(int fd) // checks if this fd is in the structures
{
    return ((strides.find(fd) != strides.end()) &&
            (current_stream.find(fd) != current_stream.end()));
}
