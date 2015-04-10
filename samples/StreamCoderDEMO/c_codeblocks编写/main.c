#include <stdio.h>
#include <stdlib.h>
#include <winsock.h>




int main()
{

    char ouBuf[1024];
    char xBuf[2];
    memset(ouBuf, 0, 1024);

    WORD x = 0xD10;
    VarToHexBytes(&x, 2, ouBuf, " ", 1);
    printf("0xD10 ��˷�:%s\r\n", ouBuf);

    memset(ouBuf, 0, 1024);
    memset(xBuf, 0, 2);
    swap16(&x, xBuf);
    VarToHexBytes(xBuf, 2, ouBuf, " ", 1);

    printf("0xD10 С�˷�:%s\r\n", ouBuf);


    WORD w;
    swap16(xBuf, &w);
    printf("xBufС�˷���ԭ����:%d\r\n", w);

    printf("sizeof(CHAR):%d\r\n", sizeof(CHAR));



    return 0;



    int ret;
    WinWSAStartup();
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
