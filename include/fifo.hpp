#pragma once

#include <iostream>
#include <fstream>
#include <cstdint>
#include <deque>

template <typename T>
class FakeFifo
{
    public:
        /* true = input to verilog, false = output from verilog */
        FakeFifo(uint8_t *clk_, uint8_t *rdy_, uint8_t *vld_, T *data_, bool dir_, bool rio_) : 
            m_dir(dir_), clk(clk_), rdy(rdy_), vld(vld_), data_port(data_), random_io(rio_) 
        {
            fifo_empty = true;
            fifo_full  = false;
            last_flag  = false;

            if(m_dir)
            {
                *data_port = 0;
                *vld = !fifo_empty;
            }
            else
            {
                *rdy = !fifo_full;
            }
        }

        void push(T data)
        {
            m_data.push_back(data);
        }

        T pop()
        {
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
            return fifo_full;
        }

        bool empty() const
        {
            return m_data.empty();
        }
        
        void eval()
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

    private:
        /* our data queue */
        std::deque<T> m_data;

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
