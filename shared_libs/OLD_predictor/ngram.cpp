#include <bits/stdc++.h>
#include "ngram.hpp"

std::unordered_map<std::string, std::unordered_map<std::string, int>> ngram_predictor;
std::deque <struct pos_bytes> track; //keeps track of the last GRAMS accesses

void push_latest_req(struct pos_bytes a)
{
	track.push_back(a);
}

int latest_req_size()
{
	return track.size();
}

void remove_oldest_req()
{
	track.pop_front();
}


std::string convert_to_string(std::deque<struct pos_bytes> latest, int start, int length)
{
	std::string a;
	if(latest.size() < length)
		return "";

	std::deque <struct pos_bytes>::iterator dqiter = latest.begin() + start;
	
	for(int i=start; i<start+length; i++)
	{
		if(dqiter == latest.end())
			return "";

		a += std::to_string(dqiter->fd) + ",";
		a += std::to_string(dqiter->pos) + ",";
		a += std::to_string(dqiter->bytes) + "+";

		*dqiter++;
	}
	return a;
}

void print_ngram()
{
	std::cout << "PRINT NGRAM" << std::endl;
	//print the complete NGRAM
	auto top_iter = ngram_predictor.begin();
	while (top_iter != ngram_predictor.end())
	{
		std::cout << "Request_string = " << top_iter->first << std::endl;
		auto second_map = top_iter->second;

		auto second_iter = second_map.begin();
		while(second_iter != second_map.end())
		{
			std::cout << second_iter->first << ": " << second_iter->second << std::endl;
			*second_iter ++;
		}
		*top_iter ++;

	}
	std::cout << "END PRINT NGRAM" << std::endl;
}


void insert_to_ngram()
{
	auto dqiter = track.begin();
	if(dqiter == track.end())
		return;
	
	std::string key = convert_to_string(track, 0, GRAMS);
	//std::cout << "Key : " << key << std::endl;

	auto gram_req = ngram_predictor.find(key); //Last N reqs

	std::string next_req = convert_to_string(track, GRAMS, 1); //latest req

	if(gram_req == ngram_predictor.end()) //If never seen such a request string
	{
		std::unordered_map<std::string, int> next;
		next[next_req] = 1;
		ngram_predictor[key] = next;
	}
	else
	{
		gram_req->second[next_req] += 1;
#ifdef DEBUG
		std::cout << "freq: " << gram_req->second[next_req] << std::endl;
#endif
	}
	return;
}

std::string predict_from_ngram()
{
	//For the latest N requests, check if there is an entry, 
	//if so, return the predicted next request
	//else, return NULL

	std::string key = convert_to_string(track, 1, GRAMS+1);

	auto gram_req = ngram_predictor.find(key); //Last N reqs

	if(gram_req != ngram_predictor.end()) //Found the key
	{
		auto second_hash = gram_req->second;
		
		//get the highest frequency result

	}

}


void insert_and_predict_from_ngram()
{
	std::deque <struct pos_bytes>::iterator dqiter = track.begin();
	if(dqiter == track.end())
		return;

	for(int i=GRAMS; i>=1; i--) //insert 1 to N gram entries in the ngram_predictor
	{
		printf("i = %d\n", i);
		std::string key = convert_to_string(track, 0, i);

		std::unordered_map<std::string,std::unordered_map<std::string, int>>::const_iterator got = ngram_predictor.find(key);

		std::string nextread = convert_to_string(track, i, 1);

		if(got == ngram_predictor.end()) //will need to insert
		{
			std::unordered_map<std::string, int> a;
			a[nextread] = 1; //freq = 1
			ngram_predictor[key] = a;
		}
		else
		{
			auto second_map = got->second; //<string,int>map
			int freq = second_map[nextread] += 1;

			std::cout << "freq: " << freq << std::endl;

		}

	}
	//print_ngram();
	return ;
}
