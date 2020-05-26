/* A test program to check if zlib is installed. */
#include <zlib.h>
int main()
{
	int ret;
	z_stream strm;
	/* allocate inflate state */
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	strm.opaque = Z_NULL;
	strm.avail_in = 0;
	strm.next_in = Z_NULL;
	ret = inflateInit(&strm);
	if (ret != Z_OK)
		return ret;	
	return 0;
}

