#include <stdio.h>
#include <stdlib.h>

long VerifyData(unsigned char* DataBuff, int DataSize)
{
    long Ret = 0;

    int i = 0;

    for (i = 0; i < DataSize; i++)
    {
        Ret += DataBuff[i];
    }

    return Ret;
}

void swap32(void * inBuf, void * outBuf)
{
    unsigned char * tmpOutBuf = (unsigned char *)(outBuf);
    unsigned char * tmpInBuf = (unsigned char *)(inBuf);

    tmpOutBuf[0] = tmpInBuf[3];
    tmpOutBuf[1] = tmpInBuf[2];
    tmpOutBuf[2] = tmpInBuf[1];
    tmpOutBuf[3] = tmpInBuf[0];
}

// �����ֽ�
void swap16(void * inBuf, unsigned char * outBuf)
{
    unsigned char * tmpOutBuf = (unsigned char *)(outBuf);
    unsigned char * tmpInBuf = (unsigned char *)(inBuf);

    tmpOutBuf[0] = tmpInBuf[1];
    tmpOutBuf[1] = tmpInBuf[0];
}

void BinToHex(unsigned char b, char * hex)
{
    //0b00020001
    unsigned char t;
    t = b>>4;    // ȡǰ4λ
    if (t>9)
    {
        hex[0] = 'A' + (t -10);
    } else
    {
        itoa(t, &hex[0], 10);
    }

    t = b & 0x0F;  // ȡ��4λ
    if (t>9)
    {
        hex[1] = 'A' + (t -10);
    } else
    {
        itoa(t, &hex[1], 10);
    }
}

int VarToHexBytes(void * inBuf, int len, char * outHexBuf, char * delimiter, short delimiterlen)
{
    int i = 0;
    int j = 0;

    char * tmpOutBuffer = outHexBuf;
    unsigned char * tmpInBuf = (unsigned char *)(inBuf);

    // �зָ���
    if (delimiterlen > 0)
    {
        for (i = 0; i < len; i++)
        {
            BinToHex(tmpInBuf[i], tmpOutBuffer);
            tmpOutBuffer = tmpOutBuffer + 2;
            j = j + 2;
            memcpy(tmpOutBuffer, delimiter, delimiterlen);
            tmpOutBuffer = tmpOutBuffer + delimiterlen;
            j = j + delimiterlen;
        }

    }else
    {   // �޷ָ���
        for (i = 0; i < len; i++)
        {
            BinToHex(tmpInBuf[i], tmpOutBuffer);
            tmpOutBuffer = tmpOutBuffer + 2;
            j = j + 2;
        }
    }

    return j;

}
