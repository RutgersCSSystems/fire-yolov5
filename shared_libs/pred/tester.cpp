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

    cout << obj.current_stream.size() << endl;
    obj.print_ngram();
}
