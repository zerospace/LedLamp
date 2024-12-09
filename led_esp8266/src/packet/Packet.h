#include <stdint.h>
#include <stdlib.h>

#define PACKET_MIN_SIZE 8
#define PACKET_MAX_SIZE UINT8_MAX + PACKET_MIN_SIZE

typedef enum PacketType: uint8_t {
    Command = 0x01,
    Response = 0x02
} PacketType;

typedef enum Function: uint8_t {
    GetState = 0xAA,
    SetState = 0xBB
} Function;

struct Packet {
    PacketType type;
    Function command;
    char data[UINT8_MAX];
};

class Parser {
    public:
        int parse(const char* buffer, size_t length, Packet *packet);
        void serialize(Packet &packet, uint8_t data_size, char *buffer, size_t &size);
    
    private:
        uint16_t crc(const char *data, size_t length);
};