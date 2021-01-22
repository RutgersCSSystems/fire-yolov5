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
        long this_stride, check_stride;
        auto deq = current_stream[fd];
        auto stream = deq.begin();

        this_stride = stream->pos + stream->bytes;
        stream++;
        this_stride = stream->pos - this_stride;

        for(int i=1; i<LENGTH; i++)
        {
            check_stride = stream->pos + stream->bytes;
            stream++;
            check_stride = stream->pos - check_stride;

#ifdef DEBUG
            printf("fd:%d check_stride:%ld\n", fd, check_stride);
#endif
            if(check_stride != this_stride)
            {
                this_stride = -1;
                break;
            }
        }
        strides[fd].stride = this_stride;
        current_stream[fd].pop_front(); //remove last element
    }
    return;
}

bool sequential::exists(int fd) // checks if this fd is in the structures
{
    //May have to remove(fd) if result is false
    return ((strides.find(fd) != strides.end()) &&
            (current_stream.find(fd) != current_stream.end()));
}
