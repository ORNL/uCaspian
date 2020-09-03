#pragma once

#include <iostream>
#include <vector>
#include <fstream>
#include <cstdint>
#include <deque>

template <typename T>
class FakeFifo
{
    public:
        /* true = input to verilog, false = output from verilog */
        FakeFifo(uint8_t *clk_, uint8_t *rdy_, uint8_t *vld_, T *data_, bool dir_, bool rio_) : 
            m_dir(dir_), random_io(rio_), clk(clk_), rdy(rdy_), vld(vld_), data_port(data_) 
        {
            fifo_empty = true;
            fifo_full  = false;
            last_flag  = false;

            if(m_dir)
            {
                *data_port = 0;
                *vld = false;
            }
            else
            {
                *rdy = false;
            }
        }

        void push(T data)
        {
            m_data.push_back(data);
        }

        void push_vec(std::vector<T> data)
        {
            for(auto &d : data) push(d);
        }

        T pop()
        {
            if(empty()) throw std::runtime_error("Cannot pop when empty");
            T ret = m_data.front();
            m_data.pop_front();
            return ret;
        }

        void push_from_file(const std::string &fname)
        {
            std::ifstream file(fname);
            char buf[sizeof(T)];
            T *item = reinterpret_cast<T*>(buf);

            while(!file.fail())
            {
                file.read(buf, sizeof(T));
                if(file.eof()) break;
                push(*item);
            }
        }

        void pop_to_file(const std::string &fname)
        {
            T item;
            char *buf = reinterpret_cast<char *>(&item);
            std::ofstream file(fname);
            
            while(!empty())
            {
                item = pop();
                file.write(buf, sizeof(T));
            }
        }

        bool full() const
        {
            //return fifo_full;
            return m_data.size() >= max_size;
        }

        bool empty() const
        {
            return m_data.empty();
        }

        size_t size() const
        {
            return m_data.size();
        }
        
        void eval(uint8_t clk, uint8_t rst)
        {
            if(rst)
            {
                if(m_dir)
                {
                    *data_port = 0;
                    *vld = false;
                }
                else
                {
                    *rdy = false;
                }
            }
            else
            {

                if(clk)
                {
                    if(m_dir)
                    {
                        *vld = !empty();
                    }
                    else
                    {
                        *rdy = !full();
                    }

                    if(*rdy && *vld)
                    {
                        if(m_dir) *data_port = pop();
                        else push(*data_port);
                    }
                }

                /*
                if(clk && *rdy && *vld)
                {
                    if(m_dir)
                    {
                        *data_port = pop();
                    }
                    else
                    {
                        push(*data_port); 
                    }
                }
                else
                {
                    if(m_dir)
                    {
                        *vld = !empty();
                    }
                    else
                    {
                        if(m_data.size() >= max_size)
                        {
                            *rdy = false;
                        }
                        else
                        {
                            *rdy = true;

                        }
                    }
                }
                */
            }
        }

#ifdef NOT_DEFD
        void eval(uint8_t clk, uint8_t rst)
        {
            if(!rst && clk)
            {

                /* data is moved when rdy and vld are asserted */
                if(*rdy && *vld)
                {
                    if(m_dir)
                    {
                        if(!fifo_empty) *data_port = pop();

                        if(fifo_empty) last_flag = true;
                        else           last_flag = false;
                    }
                    else
                    {
                        push(*data_port);
                    }
                }

                /* when fifo is empty & outputs to verilog, valid should be de-asserted */
                if(empty()) fifo_empty = true;
                else        fifo_empty = false;

                if(!m_dir) *rdy = !fifo_full;
                else       *vld = !last_flag || !fifo_empty;
            }
        }
#endif

    private:
        /* our data queue */
        std::deque<T> m_data;

        const int max_size = 32;

        /* true = input to verilog, false = output from verilog */
        bool    m_dir;
        bool    random_io;
        uint8_t fifo_full;
        uint8_t fifo_empty;
        uint8_t last_flag;
        
        /* pointers into verilator obj */
        uint8_t *clk;
        uint8_t *rdy;
        uint8_t *vld;
        T *data_port;
};

typedef FakeFifo<uint8_t> ByteFifo;
