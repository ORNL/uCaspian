#pragma once
#include <cstdint>

enum class RX_PCK
{
    NONE,
    CFG_ACK    = 0x70,
    CLEAR_ACK  = 0x0C,
    METRIC     = 0x02,
    TIME_UPD   = 0x01,
    FIRE       = 0x80
};

enum class TX_PCK
{
    NONE,
    FIRE       = 0x80,
    STEP       = 0x01,
    METRIC     = 0x02,
    CLEAR_ACT  = 0x04,
    CLEAR_CFG  = 0x08,
    CFG_N      = 0x10,
    CFG_SYN    = 0x20,
    CFG_SYNS   = 0x40
};

struct NeuronConfig
{
    uint8_t  addr;
    uint8_t  threshold;
    bool     output;
    uint8_t  leak;
    uint16_t first_syn;
    uint8_t  syn_cnt;
};

struct SynapseConfig
{
    uint16_t addr;
    int8_t   weight;
    uint8_t  target;
    uint8_t  delay;
};

int tx_input_fire(uint8_t *buf, uint8_t id, uint8_t value)
{
    buf[0] = TX_PCK::FIRE | (id & 127);
    buf[1] = value;

    // return number of bytes
    return 2;
}

int tx_step(uint8_t *buf, uint8_t steps)
{
    buf[0] = TX_PCK::STEP;
    buf[1] = steps;
    return 2;
}

int tx_clear_act(uint8_t *buf)
{
    buf[0] = TX_PCK::CLEAR_ACT;
    return 1;
}

int tx_clear_cfg(uint8_t *buf)
{
    buf[0] = TX_PCK::CLEAR_CFG;
    return 1;
}

int tx_metric(uint8_t *buf, uint8_t metric)
{
    buf[0] = TX_PCK::METRIC;
    buf[1] = metric;
    return 2;
}

int tx_cfg_neuron(uint8_t *buf, NeuronConfig &n)
{
    buf[0] = TX_PCK::CFG_N;
    buf[1] = n.addr;
    buf[2] = n.threshold;
    buf[3] = (n.output << 3) | (n.leak & 0x07);
    buf[4] = (n.first_syn >> 8);
    buf[5] = (n.first_syn & 0xFF);
    buf[6] = n.syn_cnt;
    return 7;
}

int tx_cfg_synapse(uint8_t *buf, SynapseConfig &s)
{
    buf[0] = TX_PCK::CFG_SYN;
    buf[1] = (s.addr >> 8);
    buf[2] = (s.addr & 0XFF);
    buf[3] = s.weight;
    buf[4] = s.target;
    buf[5] = s.delay;
    return 6;
}
