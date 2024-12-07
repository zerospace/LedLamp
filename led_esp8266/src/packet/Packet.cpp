#include "Packet.h"
#include <memory.h>

int Parser::parse(const char* buffer, size_t length, Packet *packet) {
    if (length < PACKET_MIN_SIZE) {
        return -1;
    }

    size_t offset = 0;
    if (memcmp(buffer, "LED", 3) != 0) {
        return -1;
    }
    offset += 3;

    packet->type = static_cast<PacketType>(buffer[offset]);
    offset += sizeof(PacketType);

    packet->command = static_cast<Function>(buffer[offset]);
    offset += sizeof(Function);

    uint8_t data_size = buffer[offset];
    offset += sizeof(uint8_t);

    if (data_size > UINT8_MAX) {
        return -1;
    }

    memset(packet->data, 0, UINT8_MAX);
    memcpy(packet->data, &buffer[offset], data_size);
    offset += data_size;
 
    uint16_t packet_crc = (buffer[offset] << 8) | buffer[offset + 1];
    offset += sizeof(uint16_t);

    uint16_t check_crc = crc(&buffer[3],  data_size + 3);
    if (check_crc != packet_crc) {
        return -1;
    }

    return 0;
}

void Parser::buffer(Packet *packet, char *buffer) {
    size_t offset = 0;
    memcpy(buffer, "LED", 3);
    offset += 3;

    buffer[offset++] = packet->type;
    buffer[offset++] = packet->command;
    buffer[offset++] = sizeof(packet->data);

    memcpy(buffer + offset, packet->data, sizeof(packet->data));
    offset += sizeof(packet->data);

    uint16_t packet_crc = crc(&buffer[3], 3 + sizeof(packet->data));
    buffer[offset++] = (packet_crc >> 8) && 0xFF;
    buffer[offset++] = packet_crc && 0xFF;
}

uint16_t Parser::crc(const char *data, size_t length) {
    uint16_t crc = 0xFFFF;
    for (size_t i = 0; i< length; i++) {
        for (uint8_t j = 0; j < 8; j++) {
            bool bit =(data[i] >> (7 - j) & 1) == 1;
            bool c15 = ((crc >> 15) & 1) == 1;
            crc <<= 1;
            if (c15 != bit) {
                crc ^= 0x1021;
            }
        }
        crc &= 0xFFFF;
    }
    return crc;
}