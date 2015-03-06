#ifndef UTILS_RAWSOCKET_H_INCLUDED
#define UTILS_RAWSOCKET_H_INCLUDED

#ifdef WIN32
#include <winsock.h>
#include <Windows.h>
typedef int				socklen_t;
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/select.h>
#include <arpa/inet.h>
typedef int				SOCKET;

//#pragma region define win32 const variable in linux
#define INVALID_SOCKET	-1
#define SOCKET_ERROR	-1
//#pragma endregion
#endif


#ifdef WIN32
// ���г�ʼ��
int WinWSAStartup();
#endif

// ����TCP�׽���
SOCKET CreateTcpSocket();

int ConnectSocket(SOCKET s, const char * host, u_short port);

int ConnectSocketTimeOut(SOCKET s, const char * host, u_short port, int ms);

// �����Ƿ������ݿ��Խ��ж�ȡ
BOOL CanRecvable(SOCKET s, UINT ims);

// ����һ��Buff,���ط�����ɵĳ���
int SendBuff(SOCKET s, void* buff, int len);

// ��������Buff��ֱ��������ɻ��߲�������
int SendEntireBuff(SOCKET s, void* buff, int len);


// ����һ������
int RecvBuffer(SOCKET s, char * buffer, int buflen);

void PrintLastError();

#endif // UTILS_RAWSOCKET_H_INCLUDED
