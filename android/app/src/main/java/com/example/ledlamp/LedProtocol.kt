package com.example.ledlamp

import java.nio.ByteBuffer

class LedProtocol {
    companion object {
        const val service = "_lamp._tcp."
        private const val frame = "LED"
    }

    enum class Command(val value: Byte) {
        INVALID(0x00.toByte()),
        GET(0xAA.toByte()),
        SET(0xBB.toByte())
    }

    enum class MessageType(val value: Byte) {
        INVALID(0x00.toByte()),
        COMMAND(0x01.toByte()),
        RESPONSE(0x02.toByte())
    }

    data class Message(
        val type: MessageType,
        val command: Command,
        val data: ByteArray? = null
    )

    fun handleInput(buffer: ByteBuffer): Message? {
        var header: LedProtocolHeader? = null
        var body: ByteArray? = null
        var checksum: Short = 0

        val packet = buffer.array()
        if (packet.copyOfRange(0, 3).contentEquals(frame.toByteArray())) {
            header = LedProtocolHeader(buffer)
            if (header.messageType != MessageType.INVALID && header.function != Command.INVALID) {
                body = ByteArray(header.length.toInt())
                buffer.position(LedProtocolHeader.encodedSize)
                buffer.get(body, 0, header.length.toInt())
                checksum = buffer.getShort(LedProtocolHeader.encodedSize + header.length.toInt())
            }
        }

        if (header != null) {
            val response = header.encodedData + (body ?: ByteArray(0))
            val crc = response.crc16()
            if (crc != checksum) {
                return null
            }
            return Message(type = header.messageType, command = header.function, data = body)
        }

        return null
    }

    fun handleOutput(message: Message): ByteArray {
        val start = frame.toByteArray()
        val header = byteArrayOf(message.type.value, message.command.value, message.data?.size?.toByte() ?: 0)
        val body = message.data ?: ByteArray(0)

        var request = header + body
        val crc = request.crc16()
        val crcData = ByteBuffer.allocate(2).putShort(crc).array()
        request += crcData
        return start + request
    }
}

data class LedProtocolHeader(
    val function: LedProtocol.Command,
    val messageType: LedProtocol.MessageType,
    val length: Byte
) {
    companion object {
        const val encodedSize: Int = 6
    }

    val encodedData: ByteArray
        get() {
            val buffer = ByteBuffer.allocate(3)
            buffer.put(messageType.value)
            buffer.put(function.value)
            buffer.put(length)
            return buffer.array()
        }

    constructor(buffer: ByteBuffer): this (
        function = LedProtocol.Command.values().find { it.value == buffer.get(4) } ?: LedProtocol.Command.INVALID,
        messageType = LedProtocol.MessageType.values().find { it.value == buffer.get(3) } ?: LedProtocol.MessageType.INVALID,
        length = buffer.get(5)
    )
}

fun ByteArray.crc16(): Short {
    val polynomial: Short = 0x1021
    var crc: Short = 0xFFFF.toShort()
    this.forEach { byte ->
        for (i in 0..7) {
            val bit = ((byte.toInt() shr (7 - i)) and 1) == 1
            val c15 = ((crc.toInt() shr 15) and 1) == 1
            crc = (crc.toInt() shl 1).toShort()
            if (c15 != bit) {
                crc = (crc.toInt() xor polynomial.toInt()).toShort()
            }
        }
        crc = (crc.toInt() and 0xFFFF.toInt()).toShort()
    }
    return crc
}