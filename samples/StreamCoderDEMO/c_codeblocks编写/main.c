#include <stdio.h>
#include <stdlib.h>
#include <winsock.h>
#include "raw/rawsocket.h"


LONG VerifyData(unsigned char* DataBuff, int DataSize)
{
    LONG Ret = 0;

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

void swap16(void * inBuf, unsigned char * outBuf)
{
    unsigned char * tmpOutBuf = (unsigned char *)(outBuf);
    unsigned char * tmpInBuf = (unsigned char *)(inBuf);

    tmpOutBuf[0] = tmpInBuf[1];
    tmpOutBuf[1] = tmpInBuf[0];
}

int main()
{
    int ret;
    WINWSAStartup();
    SOCKET s = CreateTcpSocket();

    printf("����һ����cд(codeblocks��д)�Ŀͻ���\n");
    printf("���ں�diocp�е�StreamCoderSERVER(samples\StreamCoderDEMO\SERVER)���в���!\n");
    printf("�÷ݴ�����Կ�ƽ̨��,������δ���в���!\n");
    printf("��Ҫ���з����(samples\StreamCoderDEMO\SERVER),�˿�Ϊ:9983!\n");

    printf("======================================================\n");

    // ����diocp echo������
    ret = ConnectSocket(s, "127.0.0.1", 9983);
    if (ret==SOCKET_ERROR)
    {
        PrintLastError();
        return;
    }
    printf("��������������ӳɹ�!\n");



    char * data;

    // ���͵�����
    data = "0123456789";

    int len;
    len = 10;

    WORD flag=0xD10;
    // ���ͱ��
    if (SendBuff(s, &flag, sizeof(WORD)) == SOCKET_ERROR)
    {
        PrintLastError();
        return;
    }
    printf("���ͱ��:%d\n", flag);

    LONG lvVerifyValue;
    lvVerifyValue = VerifyData(data, 10);
    // ������֤��
    if (SendBuff(s, &lvVerifyValue, sizeof(lvVerifyValue)) == SOCKET_ERROR)
    {
        PrintLastError();
        return;
    }
    printf("��������У����:%d\n", lvVerifyValue);

    unsigned char tempBuff[10];
    swap32(&len, tempBuff);
    // �������ݳ���
    if (SendBuff(s, tempBuff, 4) == SOCKET_ERROR)
    {
        PrintLastError();
        return;
    }
    printf("���ͳ�������:%d\n", len);

    // ��������
    if (SendBuff(s, data, 10) == SOCKET_ERROR)
    {
        PrintLastError();
        return;
    }

    printf("��������:%d\n", len);

    printf("======================================================\n");

    printf("׼���н�������.....");

    // ��ʼ���ݽ���

    // Flag
    flag = 0;
    if (RecvBuffer(s, &flag, sizeof(WORD))== SOCKET_ERROR)
    {
        PrintLastError();
        return;
    }
    printf("���ܵ����ݱ��:%d\n", flag);

    // ��֤��
    lvVerifyValue= 0;
    if (RecvBuffer(s, &lvVerifyValue, sizeof(lvVerifyValue))== SOCKET_ERROR)
    {
        PrintLastError();
        return;
    }
    printf("���ܵ�����У����:%d\n", lvVerifyValue);

    int recvLen;
    // �������ݳ���
    if (RecvBuffer(s, tempBuff, sizeof(int))== SOCKET_ERROR)
    {
        PrintLastError();
        return;
    }
    swap32(tempBuff, &recvLen);
    printf("���ܵ����ݳ���:%d\n", recvLen);


    unsigned char * recvData = malloc(recvLen);



    // ��������
    if (RecvBuffer(s, recvData, recvLen)== SOCKET_ERROR)
    {
        PrintLastError();
        free(recvData);
        return;
    }

    printf("���յ�����:%s", recvData);

    free(recvData);


    return 0;
}
