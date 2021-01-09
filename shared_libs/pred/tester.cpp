#include "ngram.hpp"

using namespace std;

int main()
{
    ngram obj;
    
    struct pos_bytes a; 


    a.fd = 1;
    a.pos = 11;
    a.bytes = 111;
    obj.insert_to_ngram(a);

    a.fd = 2;
    a.pos = 22;
    a.bytes = 222;
    obj.insert_to_ngram(a);

    a.fd = 3;
    a.pos = 33;
    a.bytes = 333;
    obj.insert_to_ngram(a);

    a.fd = 4;
    a.pos = 44;
    a.bytes = 444;
    obj.insert_to_ngram(a);

    a.fd = 1;
    a.pos = 11;
    a.bytes = 111;
    obj.insert_to_ngram(a);

    a.fd = 2;
    a.pos = 22;
    a.bytes = 222;
    obj.insert_to_ngram(a);

    a.fd = 3;
    a.pos = 33;
    a.bytes = 333;
    obj.insert_to_ngram(a);

    a.fd = 5;
    a.pos = 55;
    a.bytes = 555;
    obj.insert_to_ngram(a);

    a.fd = 2;
    a.pos = 22;
    a.bytes = 222;
    obj.insert_to_ngram(a);

    a.fd = 3;
    a.pos = 33;
    a.bytes = 333;
    obj.insert_to_ngram(a);

    a.fd = 5;
    a.pos = 55;
    a.bytes = 555;
    obj.insert_to_ngram(a);

    cout << obj.current_stream.size() << endl;
    //obj.print_ngram();


    /*
    std::multimap<float, std::string> next = obj.get_next_n_accesses(3);

    auto not_needed = obj.get_notneeded(next);

    cout << "############################" << endl;
    for(auto i : next)
        cout << i.first << " " << i.second << endl;
    cout << "############################" << endl;
    for(auto j : not_needed)
	    cout << j << endl;
    cout << "############################" << endl;

    string str = "2,22,222+3,33,333+";

    cout << obj.get_max_freq_access(str) << endl;
    auto d = string_to_deque(obj.get_max_freq_access(str));
    cout << d[0].fd << endl;
    cout << d[0].pos << endl;
    cout << d[0].bytes << endl;
//std::string ngram::get_max_freq_access(std::string first_key) //ret access with max freq
    */
    obj.print_ngram();
    obj.remove_from_ngram(2);
    cout << "##########################" << endl;
    obj.print_ngram();
    return 0;
}
