#!/usr/bin/env ruby
# encoding: ASCII-8BIT
require './metasm/metasm'
# require "c:\\UnixTools\\metasm\\metasm"
include Metasm

require 'pp'
require 'digest/md5'
require 'date'
require 'optparse'

opts = {}
OptionParser.new { |opt|
	opt.banner = 'Usage: AnalyzeIt.rb [-f] <executable>'
	opt.on('-f', '--fast', 'use fast disassemble') { $FASTDISAS = true }
	opt.on('-v', '--verbose', 'use fast disassemble') { $VERBOSEOPT = true }
	opt.on('-g', '--gui', 'show GUI at end of script') { $SHOWGUI = true }
	opt.on('-p', '--peid', 'Use PEiD database') { $SHOWGUI = true }
	opt.on('-u', '--update', 'update sql') { $UPDATE_SQL = true }
	opt.on('-s', '--simple', 'simple output (no sql / not verbose)') { $SIMPLE = true }
}.parse!(ARGV)

Encoding.default_internal = Encoding.find('ASCII-8BIT')
Encoding.default_external = Encoding.find('ASCII-8BIT')

@sqlrapport = ""
@IDAscript = ""

@sectionsInfos = {}

ori_renamed_functions = {}
ori_comments = {}
knownCfg = {}

checkedFunc = ["CreateProcessW", "CreateProcessA", "MoveFileW", "MoveFileA", "CopyFileW", "CopyFileA", "CopyFile", "DeleteFileA", "DeleteFileW", "RegCreateKeyA", "RegCreateKeyW", "RegSetValueA", "RegSetValueExA", "RegSetValueExW", "CreateDirectoryA", 'CreateDirectoryExA', 'CreateDirectoryExW', 'CreateDirectoryW','CreateServiceA' ,'CreateServiceW','RegOpenKeyA' ,'RegOpenKeyExA' ,'RegOpenKeyExW' ,'RegOpenKeyW', 'InternetCheckConnectionA', 'InternetCheckConnectionW','InternetOpenA', 'InternetOpenUrlA', 'InternetOpenUrlW', 'InternetOpenW', 'InternetConnectA', 'InternetConnectW', 'HttpAddRequestHeadersA', 'HttpAddRequestHeadersW','WSAAddressToStringA', 'WSAAddressToStringW', 'WSAAsyncGetHostByAddr', 'WSAAsyncGetHostByName','CheckRemoteDebuggerPresent','DbgBreakPoint','SHRegSetUSValueA','SHRegSetUSValueW','VirtualProtect','VirtualProtectEx','URLDownloadToFile','WinExec','send','connect','system','OpenServiceA','OpenServiceW','OpenSCManagerA','OpenSCManagerW','CoCreateInstance','gethostbyname','SHGetValueA','SHGetValueW','inet_addr','IoCreateSymbolicLink','IoCreateDevice','RtlAppendUnicodeToString','ZwCreateFile','ZwQueryInformationFile','ZwQuerySystemInformation','ZwOpenKey','ZwEnumerateKey','RtlWriteRegistryValue','RtlInitUnicodeString','OpenProcess', 'CreateRemoteThread', 'WriteProcessMemory','OpenEventA','OpenEventW','CreateEventA','CreateEventW']
@tbFuncName = {}
@tbComments = {}

# $VERBOSE = true
# $SHOWGUI = 1

cryptoPatterns = [["AES_forward_box",["\x63\x7c\x77\x7b\xf2\x6b\x6f\xc5\x30\x01\x67\x2b\xfe\xd7\xab\x76","\xca\x82\xc9\x7d\xfa\x59\x47\xf0\xad\xd4\xa2\xaf\x9c\xa4\x72\xc0","\xb7\xfd\x93\x26\x36\x3f\xf7\xcc\x34\xa5\xe5\xf1\x71\xd8\x31\x15","\x04\xc7\x23\xc3\x18\x96\x05\x9a\x07\x12\x80\xe2\xeb\x27\xb2\x75","\x09\x83\x2c\x1a\x1b\x6e\x5a\xa0\x52\x3b\xd6\xb3\x29\xe3\x2f\x84","\x53\xd1\x00\xed\x20\xfc\xb1\x5b\x6a\xcb\xbe\x39\x4a\x4c\x58\xcf","\xd0\xef\xaa\xfb\x43\x4d\x33\x85\x45\xf9\x02\x7f\x50\x3c\x9f\xa8","\x51\xa3\x40\x8f\x92\x9d\x38\xf5\xbc\xb6\xda\x21\x10\xff\xf3\xd2","\xcd\x0c\x13\xec\x5f\x97\x44\x17\xc4\xa7\x7e\x3d\x64\x5d\x19\x73","\x60\x81\x4f\xdc\x22\x2a\x90\x88\x46\xee\xb8\x14\xde\x5e\x0b\xdb","\xe0\x32\x3a\x0a\x49\x06\x24\x5c\xc2\xd3\xac\x62\x91\x95\xe4\x79","\xe7\xc8\x37\x6d\x8d\xd5\x4e\xa9\x6c\x56\xf4\xea\x65\x7a\xae\x08","\xba\x78\x25\x2e\x1c\xa6\xb4\xc6\xe8\xdd\x74\x1f\x4b\xbd\x8b\x8a","\x70\x3e\xb5\x66\x48\x03\xf6\x0e\x61\x35\x57\xb9\x86\xc1\x1d\x9e","\xe1\xf8\x98\x11\x69\xd9\x8e\x94\x9b\x1e\x87\xe9\xce\x55\x28\xdf","\x8c\xa1\x89\x0d\xbf\xe6\x42\x68\x41\x99\x2d\x0f\xb0\x54\xbb\x16"]],
["AES_inverse_box",["\x52\x09\x6a\xd5\x30\x36\xa5\x38\xbf\x40\xa3\x9e\x81\xf3\xd7\xfb","\x7c\xe3\x39\x82\x9b\x2f\xff\x87\x34\x8e\x43\x44\xc4\xde\xe9\xcb","\x54\x7b\x94\x32\xa6\xc2\x23\x3d\xee\x4c\x95\x0b\x42\xfa\xc3\x4e","\x08\x2e\xa1\x66\x28\xd9\x24\xb2\x76\x5b\xa2\x49\x6d\x8b\xd1\x25","\x72\xf8\xf6\x64\x86\x68\x98\x16\xd4\xa4\x5c\xcc\x5d\x65\xb6\x92","\x6c\x70\x48\x50\xfd\xed\xb9\xda\x5e\x15\x46\x57\xa7\x8d\x9d\x84","\x90\xd8\xab\x00\x8c\xbc\xd3\x0a\xf7\xe4\x58\x05\xb8\xb3\x45\x06","\xd0\x2c\x1e\x8f\xca\x3f\x0f\x02\xc1\xaf\xbd\x03\x01\x13\x8a\x6b","\x3a\x91\x11\x41\x4f\x67\xdc\xea\x97\xf2\xcf\xce\xf0\xb4\xe6\x73","\x96\xac\x74\x22\xe7\xad\x35\x85\xe2\xf9\x37\xe8\x1c\x75\xdf\x6e","\x47\xf1\x1a\x71\x1d\x29\xc5\x89\x6f\xb7\x62\x0e\xaa\x18\xbe\x1b","\xfc\x56\x3e\x4b\xc6\xd2\x79\x20\x9a\xdb\xc0\xfe\x78\xcd\x5a\xf4","\x1f\xdd\xa8\x33\x88\x07\xc7\x31\xb1\x12\x10\x59\x27\x80\xec\x5f","\x60\x51\x7f\xa9\x19\xb5\x4a\x0d\x2d\xe5\x7a\x9f\x93\xc9\x9c\xef","\xa0\xe0\x3b\x4d\xae\x2a\xf5\xb0\xc8\xeb\xbb\x3c\x83\x53\x99\x61","\x17\x2b\x04\x7e\xba\x77\xd6\x26\xe1\x69\x14\x63\x55\x21\x0c\x7d"]],
["Serpent_S-Box",["\x0e\x04\x0d\x01\x02\x0f\x0b\x08\x03\x0a\x06\x0c\x05\x09\x00\x07", "\x00\x0f\x07\x04\x0e\x02\x0d\x01\x0a\x06\x0c\x0b\x09\x05\x03\x08", "\x04\x01\x0e\x08\x0d\x06\x02\x0b\x0f\x0c\x09\x07\x03\x0a\x05\x00", "\x0f\x0c\x08\x02\x04\x09\x01\x07\x05\x0b\x03\x0e\x0a\x00\x06\x0d", "\x0f\x01\x08\x0e\x06\x0b\x03\x04\x09\x07\x02\x0d\x0c\x00\x05\x0a", "\x03\x0d\x04\x07\x0f\x02\x08\x0e\x0c\x00\x01\x0a\x06\x09\x0b\x05", "\x00\x0e\x07\x0b\x0a\x04\x0d\x01\x05\x08\x0c\x06\x09\x03\x02\x0f", "\x0d\x08\x0a\x01\x03\x0f\x04\x02\x0b\x06\x07\x0c\x00\x05\x0e\x09", "\x0a\x00\x09\x0e\x06\x03\x0f\x05\x01\x0d\x0c\x07\x0b\x04\x02\x08", "\x0d\x07\x00\x09\x03\x04\x06\x0a\x02\x08\x05\x0e\x0c\x0b\x0f\x01", "\x0d\x06\x04\x09\x08\x0f\x03\x00\x0b\x01\x02\x0c\x05\x0a\x0e\x07", "\x01\x0a\x0d\x00\x06\x09\x08\x07\x04\x0f\x0e\x03\x0b\x05\x02\x0c", "\x07\x0d\x0e\x03\x00\x06\x09\x0a\x01\x02\x08\x05\x0b\x0c\x04\x0f", "\x0d\x08\x0b\x05\x06\x0f\x00\x03\x04\x07\x02\x0c\x01\x0a\x0e\x09", "\x0a\x06\x09\x00\x0c\x0b\x07\x0d\x0f\x01\x03\x0e\x05\x02\x08\x04", "\x03\x0f\x00\x06\x0a\x01\x0d\x08\x09\x04\x05\x0b\x0c\x07\x02\x0e", "\x02\x0c\x04\x01\x07\x0a\x0b\x06\x08\x05\x03\x0f\x0d\x00\x0e\x09", "\x0e\x0b\x02\x0c\x04\x07\x0d\x01\x05\x00\x0f\x0a\x03\x09\x08\x06", "\x04\x02\x01\x0b\x0a\x0d\x07\x08\x0f\x09\x0c\x05\x06\x03\x00\x0e", "\x0b\x08\x0c\x07\x01\x0e\x02\x0d\x06\x0f\x00\x09\x0a\x04\x05\x03", "\x0c\x01\x0a\x0f\x09\x02\x06\x08\x00\x0d\x03\x04\x0e\x07\x05\x0b", "\x0a\x0f\x04\x02\x07\x0c\x09\x05\x06\x01\x0d\x0e\x00\x0b\x03\x08", "\x09\x0e\x0f\x05\x02\x08\x0c\x03\x07\x00\x04\x0a\x01\x0d\x0b\x06", "\x04\x03\x02\x0c\x09\x05\x0f\x0a\x0b\x0e\x01\x07\x06\x00\x08\x0d", "\x04\x0b\x02\x0e\x0f\x00\x08\x0d\x03\x0c\x09\x07\x05\x0a\x06\x01", "\x0d\x00\x0b\x07\x04\x09\x01\x0a\x0e\x03\x05\x0c\x02\x0f\x08\x06", "\x01\x04\x0b\x0d\x0c\x03\x07\x0e\x0a\x0f\x06\x08\x00\x05\x09\x02", "\x06\x0b\x0d\x08\x01\x04\x0a\x07\x09\x05\x00\x0f\x0e\x02\x03\x0c", "\x0d\x02\x08\x04\x06\x0f\x0b\x01\x0a\x09\x03\x0e\x05\x00\x0c\x07", "\x01\x0f\x0d\x08\x0a\x03\x07\x04\x0c\x05\x06\x0b\x00\x0e\x09\x02", "\x07\x0b\x04\x01\x09\x0c\x0e\x02\x00\x06\x0a\x0d\x0f\x03\x05\x08", "\x02\x01\x0e\x07\x04\x0a\x08\x0d\x0f\x0c\x09\x00\x03\x05\x06\x0b"]],
["Serpent_inverse_S-Box",["\x0e\x03\x04\x08\x01\x0c\x0a\x0f\x07\x0d\x09\x06\x0b\x02\x00\x05", "\x00\x07\x05\x0e\x03\x0d\x09\x02\x0f\x0c\x08\x0b\x0a\x06\x04\x01", "\x0f\x01\x06\x0c\x00\x0e\x05\x0b\x03\x0a\x0d\x07\x09\x04\x02\x08", "\x0d\x06\x03\x0a\x04\x08\x0e\x07\x02\x05\x0c\x09\x01\x0f\x0b\x00", "\x0d\x01\x0a\x06\x07\x0e\x04\x09\x02\x08\x0f\x05\x0c\x0b\x03\x00", "\x09\x0a\x05\x00\x02\x0f\x0c\x03\x06\x0d\x0b\x0e\x08\x01\x07\x04", "\x00\x07\x0e\x0d\x05\x08\x0b\x02\x09\x0c\x04\x03\x0a\x06\x01\x0f", "\x0c\x03\x07\x04\x06\x0d\x09\x0a\x01\x0f\x02\x08\x0b\x00\x0e\x05", "\x01\x08\x0e\x05\x0d\x07\x04\x0b\x0f\x02\x00\x0c\x0a\x09\x03\x06", "\x02\x0f\x08\x04\x05\x0a\x06\x01\x09\x03\x07\x0d\x0c\x00\x0b\x0e", "\x07\x09\x0a\x06\x02\x0c\x01\x0f\x04\x03\x0d\x08\x0b\x00\x0e\x05", "\x03\x00\x0e\x0b\x08\x0d\x04\x07\x06\x05\x01\x0c\x0f\x02\x0a\x09", "\x04\x08\x09\x03\x0e\x0b\x05\x00\x0a\x06\x07\x0c\x0d\x01\x02\x0f", "\x06\x0c\x0a\x07\x08\x03\x04\x09\x01\x0f\x0d\x02\x0b\x00\x0e\x05", "\x03\x09\x0d\x0a\x0f\x0c\x01\x06\x0e\x02\x00\x05\x04\x07\x0b\x08", "\x02\x05\x0e\x00\x09\x0a\x03\x0d\x07\x08\x04\x0b\x0c\x06\x0f\x01", "\x0d\x03\x00\x0a\x02\x09\x07\x04\x08\x0f\x05\x06\x01\x0c\x0e\x0b", "\x09\x07\x02\x0c\x04\x08\x0f\x05\x0e\x0d\x0b\x01\x03\x06\x00\x0a", "\x0e\x02\x01\x0d\x00\x0b\x0c\x06\x07\x09\x04\x03\x0a\x05\x0f\x08", "\x0a\x04\x06\x0f\x0d\x0e\x08\x03\x01\x0b\x0c\x00\x02\x07\x05\x09", "\x08\x01\x05\x0a\x0b\x0e\x06\x0d\x07\x04\x02\x0f\x00\x09\x0c\x03", "\x0c\x09\x03\x0e\x02\x07\x08\x04\x0f\x06\x00\x0d\x05\x0a\x0b\x01", "\x09\x0c\x04\x07\x0a\x03\x0f\x08\x05\x00\x0b\x0e\x06\x0d\x01\x02", "\x0d\x0a\x02\x01\x00\x05\x0c\x0b\x0e\x04\x07\x08\x03\x0f\x09\x06", "\x05\x0f\x02\x08\x00\x0c\x0e\x0b\x06\x0a\x0d\x01\x09\x07\x03\x04", "\x01\x06\x0c\x09\x04\x0a\x0f\x03\x0e\x05\x07\x02\x0b\x00\x08\x0d", "\x0c\x00\x0f\x05\x01\x0d\x0a\x06\x0b\x0e\x08\x02\x04\x03\x07\x09", "\x0a\x04\x0d\x0e\x05\x09\x00\x07\x03\x08\x06\x01\x0f\x02\x0c\x0b", "\x0d\x07\x01\x0a\x03\x0c\x04\x0f\x02\x09\x08\x06\x0e\x00\x0b\x05", "\x0c\x00\x0f\x05\x07\x09\x0a\x06\x03\x0e\x04\x0b\x08\x02\x0d\x01", "\x08\x03\x07\x0d\x02\x0e\x09\x00\x0f\x04\x0a\x01\x05\x0b\x06\x0c", "\x0b\x01\x00\x0c\x04\x0d\x0e\x03\x06\x0a\x05\x0f\x09\x07\x02\x08"]],
["MD5/SHA1",["\x01\x23\x45\x67", "\x89\xab\xcd\xef", "\xfe\xdc\xba\x98", "\x76\x54\x32\x10", "\xf0\xe1\xd2\xc3"]],
["TigerInit",["\xa5\xa5\xa5\xa5\xa5\xa5\xa5\xa5", "\xef\xcd\xab\x89\x67\x45\x23\x01", "\x10\x32\x54\x76\x98\xba\xdc\xfe", "\x87\xe1\xb2\xc3\xb4\xa5\x96\xf0"]],
["RC5_box",["\x63\x51\xe1\xb7","\x1c\xcb\x18\x56","\xd5\x44\x50\xf4","\x8e\xbe\x87\x92","\x47\x38\xbf\x30","\x00\xb2\xf6\xce","\xb9\x2b\x2e\x6d","\x72\xa5\x65\x0b","\x2b\x1f\x9d\xa9","\xe4\x98\xd4\x47","\x9d\x12\x0c\xe6","\x56\x8c\x43\x84","\x0f\x06\x7b\x22","\xc8\x7f\xb2\xc0","\x81\xf9\xe9\x5e","\x3a\x73\x21\xfd","\xf3\xec\x58\x9b","\xac\x66\x90\x39","\x65\xe0\xc7\xd7","\x1e\x5a\xff\x75","\xd7\xd3\x36\x14","\x90\x4d\x6e\xb2","\x49\xc7\xa5\x50","\x02\x41\xdd\xee","\xbb\xba\x14\x8d","\x74\x34\x4c\x2b","\x2d\xae\x83\xc9","\xe6\x27\xbb\x67","\x9f\xa1\xf2\x05","\x58\x1b\x2a\xa4","\x11\x95\x61\x42","\xca\x0e\x99\xe0"]],
["IDEA_Box",["\xb7\xe1\x51\x62\x8a\xed\x2a\x6a\xbf\x71\x58\x80\x9c\xf4\xf3\xc7\x62\xe7\x16\x0f\x38\xb4\xda\x56\xa7\x84\xd9\x04\x51\x90\xcf\xef"]],
["Twofish_S-Box",["\x08\x01\x07\x0d\x06\x0f\x03\x02\x00\x0b\x05\x09\x0e\x0c\x0a\x04", "\x02\x08\x0b\x0d\x0f\x07\x06\x0e\x03\x01\x09\x04\x00\x0a\x0c\x05", "\x0e\x0c\x0b\x08\x01\x02\x03\x05\x0f\x04\x0a\x06\x07\x00\x09\x0d", "\x01\x0e\x02\x0b\x04\x0c\x03\x07\x06\x0d\x0a\x05\x0f\x09\x00\x08", "\x0b\x0a\x05\x0e\x06\x0d\x09\x00\x0c\x08\x0f\x03\x02\x04\x07\x01", "\x04\x0c\x07\x05\x01\x06\x09\x0a\x00\x0e\x0d\x08\x02\x0b\x03\x0f", "\x0d\x07\x0f\x04\x01\x02\x06\x0e\x09\x0b\x03\x00\x08\x05\x0c\x0a", "\x0b\x09\x05\x01\x0c\x03\x0d\x0e\x06\x04\x07\x0f\x02\x00\x08\x0a"]],
["SQUARE_SHARK_dec",["\x35\xbe\x07\x2e\x53\x69\xdb\x28\x6f\xb7\x76\x6b\x0c\x7d\x36\x8b\x92\xbc\xa9\x32\xac\x38\x9c\x42\x63\xc8\x1e\x4f\x24\xe5\xf7\xc9\x61\x8d\x2f\x3f\xb3\x65\x7f\x70\xaf\x9a\xea\xf5\x5b\x98\x90\xb1\x87\x71\x72\xed\x37\x45\x68\xa3\xe3\xef\x5c\xc5\x50\xc1\xd6\xca\x5a\x62\x5f\x26\x09\x5d\x14\x41\xe8\x9d\xce\x40\xfd\x08\x17\x4a\x0f\xc7\xb4\x3e\x12\xfc\x25\x4b\x81\x2c\x04\x78\xcb\xbb\x20\xbd\xf9\x29\x99\xa8\xd3\x60\xdf\x11\x97\x89\x7e\xfa\xe0\x9b\x1f\xd2\x67\xe2\x64\x77\x84\x2b\x9e\x8a\xf1\x6d\x88\x79\x74\x57\xdd\xe6\x39\x7b\xee\x83\xe1\x58\xf2\x0d\x34\xf8\x30\xe9\xb9\x23\x54\x15\x44\x0b\x4d\x66\x3a\x03\xa2\x91\x94\x52\x4c\xc3\x82\xe7\x80\xc0\xb6\x0e\xc2\x6c\x93\xec\xab\x43\x95\xf6\xd8\x46\x86\x05\x8c\xb0\x75\x00\xcc\x85\xd7\x3d\x73\x7a\x48\xe4\xd1\x59\xad\xb8\xc6\xd0\xdc\xa1\xaa\x02\x1d\xbf\xb5\x9f\x51\xc4\xa5\x10\x22\xcf\x01\xba\x8f\x31\x7c\xae\x96\xda\xf0\x56\x47\xd4\xeb\x4e\xd9\x13\x8e\x49\x55\x16\xff\x3b\xf4\xa4\xb2\x06\xa0\xa7\xfb\x1b\x6e\x3c\x33\xcd\x18\x5e\x6a\xd5\xa6\x21\xde\xfe\x2a\x1c\xf3\x0a\x1a\x19\x27\x2d"]],
["Twofish_mds",["\x75\x32\xbc\xbc\xf3\x21\xec\xec\xc6\x43\x20\x20\xf4\xc9\xb3\xb3\xdb\x03\xda\xda\x7b\x8b\x02\x02\xfb\x2b\xe2\xe2\xc8\xfa\x9e\x9e\x4a\xec\xc9\xc9\xd3\x09\xd4\xd4\xe6\x6b\x18\x18\x6b\x9f\x1e\x1e\x45\x0e\x98\x98\x7d\x38\xb2\xb2\xe8\xd2\xa6\xa6\x4b\xb7\x26\x26\xd6\x57\x3c\x3c\x32\x8a\x93\x93\xd8\xee\x82\x82\xfd\x98\x52\x52\x37\xd4\x7b\x7b\x71\x37\xbb\xbb\xf1\x97\x5b\x5b\xe1\x83\x47\x47\x30\x3c\x24\x24\x0f\xe2\x51\x51\xf8\xc6\xba\xba\x1b\xf3\x4a\x4a\x87\x48\xbf\xbf\xfa\x70\x0d\x0d\x06\xb3\xb0\xb0\x3f\xde\x75\x75\x5e\xfd\xd2\xd2\xba\x20\x7d\x7d\xae\x31\x66\x66\x5b\xa3\x3a\x3a\x8a\x1c\x59\x59\x00\x00\x00\x00\xbc\x93\xcd\xcd\x9d\xe0\x1a\x1a\x6d\x2c\xae\xae\xc1\xab\x7f\x7f\xb1\xc7\x2b\x2b\x0e\xb9\xbe\xbe\x80\xa0\xe0\xe0\x5d\x10\x8a\x8a\xd2\x52\x3b\x3b\xd5\xba\x64\x64\xa0\x88\xd8\xd8\x84\xa5\xe7\xe7\x07\xe8\x5f\x5f\x14\x11\x1b\x1b\xb5\xc2\x2c\x2c\x90\xb4\xfc\xfc\x2c\x27\x31\x31\xa3\x65\x80\x80\xb2\x2a\x73\x73\x73\x81\x0c\x0c\x4c\x5f\x79\x79\x54\x41\x6b\x6b\x92\x02\x4b\x4b\x74\x69\x53\x53\x36\x8f\x94\x94\x51\x1f\x83\x83\x38\x36\x2a\x2a\xb0\x9c\xc4\xc4\xbd\xc8"]],
["PKCS_Tiger",["\x30\x29\x30\x0d\x06\x09\x2b\x06\x01\x04\x01\xda\x47\x0c\x02\x05\x00\x04\x18"]],
["rijndael_td3",["\x51\x50\xa7\xf4\x7e\x53\x65\x41\x1a\xc3\xa4\x17\x3a\x96\x5e\x27\x3b\xcb\x6b\xab\x1f\xf1\x45\x9d\xac\xab\x58\xfa\x4b\x93\x03\xe3\x20\x55\xfa\x30\xad\xf6\x6d\x76\x88\x91\x76\xcc\xf5\x25\x4c\x02\x4f\xfc\xd7\xe5\xc5\xd7\xcb\x2a\x26\x80\x44\x35\xb5\x8f\xa3\x62\xde\x49\x5a\xb1\x25\x67\x1b\xba\x45\x98\x0e\xea\x5d\xe1\xc0\xfe\xc3\x02\x75\x2f\x81\x12\xf0\x4c\x8d\xa3\x97\x46\x6b\xc6\xf9\xd3\x03\xe7\x5f\x8f\x15\x95\x9c\x92\xbf\xeb\x7a\x6d\x95\xda\x59\x52\xd4\x2d\x83\xbe\x58\xd3\x21\x74\x49\x29\x69\xe0\x8e\x44\xc8\xc9\x75\x6a\x89\xc2\xf4\x78\x79\x8e\x99\x6b\x3e\x58\x27\xdd\x71\xb9\xbe\xb6\x4f\xe1\xf0\x17\xad\x88\xc9\x66\xac\x20\x7d\xb4\x3a\xce\x63\x18\x4a\xdf\xe5\x82\x31\x1a\x97\x60\x33\x51\x62\x45\x7f\x53\xb1\xe0\x77\x64\xbb\x84\xae\x6b\xfe\x1c\xa0\x81\xf9\x94\x2b\x08\x70\x58\x68\x48\x8f\x19\xfd\x45\x94\x87\x6c\xde\x52\xb7\xf8\x7b\xab\x23\xd3\x73\x72\xe2"]],
["MD5mac_t",["\x97\xef\x45\xac\x29\x0f\x43\xcd\x45\x7e\x1b\x55\x1c\x80\x11\x34\xb1\x77\xce\x96\x2e\x72\x8e\x7c\x5f\x5a\xab\x0a\x36\x43\xbe\x18\x9d\x21\xb4\x21\xbc\x87\xb9\x4d\xa2\x9d\x27\xbd\xc7\x5b\xd7\xc3"]],
["zdeflate_lengthCodes",["\x01\x01\x00\x00\x02\x01\x00\x00\x03\x01\x00\x00\x04\x01\x00\x00\x05\x01\x00\x00\x06\x01\x00\x00\x07\x01\x00\x00\x08\x01\x00\x00\x09\x01\x00\x00\x09\x01\x00\x00\x0a\x01\x00\x00\x0a\x01\x00\x00\x0b\x01\x00\x00\x0b\x01\x00\x00\x0c\x01\x00\x00\x0c\x01\x00\x00\x0d\x01\x00\x00\x0d\x01\x00\x00\x0d\x01\x00\x00\x0d\x01\x00\x00\x0e\x01\x00\x00\x0e\x01\x00\x00\x0e\x01\x00\x00\x0e\x01\x00\x00\x0f\x01\x00\x00\x0f\x01\x00\x00\x0f\x01\x00\x00\x0f\x01\x00\x00\x10\x01\x00"]],
["zinflate_lengthExtraBits",["\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x02\x00\x00\x00\x02\x00\x00\x00\x02\x00\x00\x00\x02\x00\x00\x00\x03\x00\x00\x00\x03\x00\x00\x00\x03\x00\x00\x00\x03\x00\x00\x00\x04\x00\x00\x00\x04\x00\x00\x00\x04\x00\x00\x00\x04\x00\x00\x00\x05\x00\x00\x00\x05\x00\x00\x00\x05\x00\x00\x00\x05\x00\x00\x00\x00\x00\x00\x00"]],
["PKCS_sha1",["\x30\x21\x30\x09\x06\x05\x2b\x24\x03\x02\x01\x05\x00\x04\x14"]],
["PKCS_sha256",["\x30\x31\x30\x0d\x06\x09\x60\x86\x48\x01\x65\x03\x04\x02\x01\x05\x00\x04\x20"]],
["HAVAL_wi2",["\x05\x00\x00\x00\x0e\x00\x00\x00\x1a\x00\x00\x00\x12\x00\x00\x00\x0b\x00\x00\x00\x1c\x00\x00\x00\x07\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x17\x00\x00\x00\x14\x00\x00\x00\x16\x00\x00\x00\x01\x00\x00\x00\x0a\x00\x00\x00\x04\x00\x00\x00\x08\x00\x00\x00\x1e\x00\x00\x00\x03\x00\x00\x00\x15\x00\x00\x00\x09\x00\x00\x00\x11\x00\x00\x00\x18\x00\x00\x00\x1d\x00\x00\x00\x06\x00\x00\x00\x13\x00\x00\x00\x0c\x00\x00\x00\x0f\x00\x00\x00\x0d\x00\x00\x00\x02\x00\x00\x00\x19\x00\x00\x00\x1f\x00\x00\x00\x1b\x00\x00\x00"]],
["zinflate_distanceExtraBits",["\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x02\x00\x00\x00\x02\x00\x00\x00\x03\x00\x00\x00\x03\x00\x00\x00\x04\x00\x00\x00\x04\x00\x00\x00\x05\x00\x00\x00\x05\x00\x00\x00\x06\x00\x00\x00\x06\x00\x00\x00\x07\x00\x00\x00\x07\x00\x00\x00\x08\x00\x00\x00\x08\x00\x00\x00\x09\x00\x00\x00\x09\x00\x00\x00\x0a\x00\x00\x00\x0a\x00\x00\x00\x0b\x00\x00\x00\x0b\x00\x00\x00\x0c\x00\x00\x00\x0c\x00\x00\x00\x0d\x00\x00\x00\x0d\x00\x00\x00"]],
["PKCS_sha512",["\x98\x2f\x8a\x42\x91\x44\x37\x71\xcf\xfb\xc0\xb5\xa5\xdb\xb5\xe9\x5b\xc2\x56\x39\xf1\x11\xf1\x59\xa4\x82\x3f\x92\xd5\x5e\x1c\xab\x98\xaa\x07\xd8\x01\x5b\x83\x12\xbe\x85\x31\x24\xc3\x7d\x0c\x55\x74\x5d\xbe\x72\xfe\xb1\xde\x80\xa7\x06\xdc\x9b\x74\xf1\x9b\xc1\xc1\x69\x9b\xe4\x86\x47\xbe\xef\xc6\x9d\xc1\x0f\xcc\xa1\x0c\x24\x6f\x2c\xe9\x2d\xaa\x84\x74\x4a\xdc\xa9\xb0\x5c\xda\x88\xf9\x76\x52\x51\x3e\x98\x6d\xc6\x31\xa8\xc8\x27\x03\xb0\xc7\x7f\x59\xbf\xf3"]],
["rijndael_td0",["\x50\xa7\xf4\x51\x53\x65\x41\x7e\xc3\xa4\x17\x1a\x96\x5e\x27\x3a\xcb\x6b\xab\x3b\xf1\x45\x9d\x1f\xab\x58\xfa\xac\x93\x03\xe3\x4b\x55\xfa\x30\x20\xf6\x6d\x76\xad\x91\x76\xcc\x88\x25\x4c\x02\xf5\xfc\xd7\xe5\x4f\xd7\xcb\x2a\xc5\x80\x44\x35\x26\x8f\xa3\x62\xb5\x49\x5a\xb1\xde\x67\x1b\xba\x25\x98\x0e\xea\x45\xe1\xc0\xfe\x5d\x02\x75\x2f\xc3\x12\xf0\x4c\x81\xa3\x97\x46\x8d\xc6\xf9\xd3\x6b\xe7\x5f\x8f\x03\x95\x9c\x92\x15\xeb\x7a\x6d\xbf\xda\x59\x52\x95\x2d\x83\xbe\xd4\xd3\x21\x74\x58\x29\x69\xe0\x49\x44\xc8\xc9\x8e\x6a\x89\xc2\x75\x78\x79\x8e\xf4\x6b\x3e\x58\x99\xdd\x71\xb9\x27\xb6\x4f\xe1\xbe\x17\xad\x88\xf0\x66\xac\x20\xc9\xb4\x3a\xce\x7d"]],
["HAVAL_wi4",["\x18\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x0e\x00\x00\x00\x02\x00\x00\x00\x07\x00\x00\x00\x1c\x00\x00\x00\x17\x00\x00\x00\x1a\x00\x00\x00\x06\x00\x00\x00\x1e\x00\x00\x00\x14\x00\x00\x00\x12\x00\x00\x00\x19\x00\x00\x00\x13\x00\x00\x00\x03\x00\x00\x00\x16\x00\x00\x00\x0b\x00\x00\x00\x1f\x00\x00\x00\x15\x00\x00\x00\x08\x00\x00\x00\x1b\x00\x00\x00\x0c\x00\x00\x00\x09\x00\x00\x00\x01\x00\x00\x00\x1d\x00\x00\x00\x05\x00\x00\x00\x0f\x00\x00\x00\x11\x00\x00\x00\x0a\x00\x00\x00\x10\x00\x00\x00\x0d\x00\x00\x00"]],
["Blowfish_p_init",["\x88\x6a\x3f\x24\xd3\x08\xa3\x85\x2e\x8a\x19\x13\x44\x73\x70\x03\x22\x38\x09\xa4\xd0\x31\x9f\x29\x98\xfa\x2e\x08\x89\x6c\x4e\xec\xe6\x21\x28\x45\x77\x13\xd0\x38\xcf\x66\x54\xbe\x6c\x0c\xe9\x34\xb7\x29\xac\xc0\xdd\x50\x7c\xc9\xb5\xd5\x84\x3f\x17\x09\x47\xb5\xd9\xd5\x16\x92\x1b\xfb\x79\x89"]],
["zinflate_lengthStarts",["\x03\x00\x00\x00\x04\x00\x00\x00\x05\x00\x00\x00\x06\x00\x00\x00\x07\x00\x00\x00\x08\x00\x00\x00\x09\x00\x00\x00\x0a\x00\x00\x00\x0b\x00\x00\x00\x0d\x00\x00\x00\x0f\x00\x00\x00\x11\x00\x00\x00\x13\x00\x00\x00\x17\x00\x00\x00\x1b\x00\x00\x00\x1f\x00\x00\x00\x23\x00\x00\x00\x2b\x00\x00\x00\x33\x00\x00\x00\x3b\x00\x00\x00\x43\x00\x00\x00\x53\x00\x00\x00\x63\x00\x00\x00\x73\x00\x00\x00\x83\x00\x00\x00\xa3\x00\x00\x00\xc3\x00\x00\x00\xe3\x00\x00\x00\x02\x01\x00\x00"]],
["SHARK_encrpytion_cbox",["\x65\xa3\xf3\x16\x8f\x83\x0d\x06\xf6\x56\xae\x5c\xee\x57\x88\xa6\x89\x4d\x2c\x3c\x35\x16\xf5\xeb\xdc\x5b\xe8\x88\xbe\x74\x21\x65\x21\x79\xc1\x86\x80\x9a\x4e\x0d\xa1\x58\xfa\xcf\x33\x7d\xba\x27\x30\xb5\x37\xa2\x04\xe1\xd9\x88\x16\xe8\xfb\xa4\x55\x87\x3b\x69\xa0\x54\xb2\x26\x18\x59\xc9\xda\xf3\x6a\x33\xfb\x69\xe3\xc2\x45\xf4\x4e\x3e\x7b\xb8\x1f\x6e\xa9\xf0\x7e\xeb\x35\x14\x8f\x57\xb7\x74\x6f\x05\x32\x0b\xf8\x9a\x83\x7a\x27\x1f\xc7\x5c\xf5\x37\xae\xd5\x37\xff\xfd"]],
["HAVAL_mc5",["\x50\xf0\x3b\xba\x98\x2a\xfb\x7e\x1d\x65\xf1\xa1\x76\x01\xaf\x39\x3e\x59\xca\x66\x88\x0e\x43\x82\x19\x86\xee\x8c\xb4\x9f\x6f\x45\xc3\xa5\x84\x7d\xbe\x5e\x8b\x3b\xd8\x75\x6f\xe0\x73\x20\xc1\x85\x9f\x44\x1a\x40\xa6\x6a\xc1\x56\x62\xaa\xd3\x4e\x06\x77\x3f\x36\x72\xdf\xfe\x1b\x3d\x02\x9b\x42\x24\xd7\xd0\x37\x48\x12\x0a\xd0\xd3\xea\x0f\xdb\x9b\xc0\xf1\x49\xc9\x72\x53\x07\x7b\x1b\x99\x80\xd8\x79\xd4\x25\xf7\xde\xe8\xf6\x1a\x50\xfe\xe3\x3b\x4c\x79\xb6\xbd\xe0\x6c\x97\xba\x06\xc0\x04\xb6\x4f\xa9\xc1\xc4\x60\x9f\x40"]],
["rijndael_td4",["\x52\x52\x52\x52\x09\x09\x09\x09\x6a\x6a\x6a\x6a\xd5\xd5\xd5\xd5\x30\x30\x30\x30\x36\x36\x36\x36\xa5\xa5\xa5\xa5\x38\x38\x38\x38\xbf\xbf\xbf\xbf\x40\x40\x40\x40\xa3\xa3\xa3\xa3\x9e\x9e\x9e\x9e\x81\x81\x81\x81\xf3\xf3\xf3\xf3\xd7\xd7\xd7\xd7\xfb\xfb\xfb\xfb\x7c\x7c\x7c\x7c\xe3\xe3\xe3\xe3\x39\x39\x39\x39\x82\x82\x82\x82\x9b\x9b\x9b\x9b\x2f\x2f\x2f\x2f\xff\xff\xff\xff\x87\x87\x87\x87\x34\x34\x34\x34\x8e\x8e\x8e\x8e\x43\x43\x43\x43\x44\x44\x44\x44\xc4"]],
["SQUARE_SHARK_enc",["\xb1\xce\xc3\x95\x5a\xad\xe7\x02\x4d\x44\xfb\x91\x0c\x87\xa1\x50\xcb\x67\x54\xdd\x46\x8f\xe1\x4e\xf0\xfd\xfc\xeb\xf9\xc4\x1a\x6e\x5e\xf5\xcc\x8d\x1c\x56\x43\xfe\x07\x61\xf8\x75\x59\xff\x03\x22\x8a\xd1\x13\xee\x88\x00\x0e\x34\x15\x80\x94\xe3\xed\xb5\x53\x23\x4b\x47\x17\xa7\x90\x35\xab\xd8\xb8\xdf\x4f\x57\x9a\x92\xdb\x1b\x3c\xc8\x99\x04\x8e\xe0\xd7\x7d\x85\xbb\x40\x2c\x3a\x45\xf1\x42\x65\x20\x41\x18\x72\x25\x93\x70\x36\x05\xf2\x0b\xa3\x79\xec\x08\x27"]],
["DES_ei",["\x20\x01\x02\x03\x04\x05\x04\x05\x06\x07\x08\x09\x08\x09\x0a\x0b\x0c\x0d\x0c\x0d\x0e\x0f\x10\x11\x10\x11\x12\x13\x14\x15\x14\x15\x16\x17\x18\x19\x18\x19\x1a\x1b\x1c\x1d\x1c\x1d\x1e\x1f\x20\x01"]],
["HAVAL_wi5",["\x1b\x00\x00\x00\x03\x00\x00\x00\x15\x00\x00\x00\x1a\x00\x00\x00\x11\x00\x00\x00\x0b\x00\x00\x00\x14\x00\x00\x00\x1d\x00\x00\x00\x13\x00\x00\x00\x00\x00\x00\x00\x0c\x00\x00\x00\x07\x00\x00\x00\x0d\x00\x00\x00\x08\x00\x00\x00\x1f\x00\x00\x00\x0a\x00\x00\x00\x05\x00\x00\x00\x09\x00\x00\x00\x0e\x00\x00\x00\x1e\x00\x00\x00\x12\x00\x00\x00\x06\x00\x00\x00\x1c\x00\x00\x00\x18\x00\x00\x00\x02\x00\x00\x00\x17\x00\x00\x00\x10\x00\x00\x00\x16\x00\x00\x00\x04\x00\x00\x00\x01"]],
["PKCS_sha384",["\x30\x41\x30\x0d\x06\x09\x60\x86\x48\x01\x65\x03\x04\x02\x02\x05\x00\x04\x30"]],
["MARS_Sbox",["\x79\xc4\xd0\x09\xe0\xff\xc8\x28\x39\x6c\xaa\x84\x87\x72\xad\x9d\xe3\x9b\xff\x7d\x61\x83\x26\xd4\xd4\xa1\x6d\xc9\x93\xcc\x74\x79\x2e\x58\xd0\x85\x05\x57\x4b\x2a\x62\x6a\xa1\x1c\x9d\x27\xbd\xc3\xe5\x25\x1f\x0f\x2f\x37\x60\x51\xfb\xc1\x95\xc6\xe4\xf1\x7f\x4d\xf4\x6b\x5f\xae\x46\xee\x72\x0d\x8a\xde\x23\xff\x83\x8e\xcf\xb1\xe2\x02\x49\xf1\x42\x1e\x98\x3e\xb6\x3e\xf5\x8b\xac\xf8\x4b\x7f\x83\x1f\x63\x83\x05\x02\x97\x25\x84\xe7\xaf\x76\xd4\x31\x79\x3a\x50\x64\x84\x4f\xf6\xc3\x64\x5c"]],
["SHA256_K",["\x98\x2f\x8a\x42\x91\x44\x37\x71\xcf\xfb\xc0\xb5\xa5\xdb\xb5\xe9\x5b\xc2\x56\x39\xf1\x11\xf1\x59\xa4\x82\x3f\x92\xd5\x5e\x1c\xab\x98\xaa\x07\xd8\x01\x5b\x83\x12\xbe\x85\x31\x24\xc3\x7d\x0c\x55\x74\x5d\xbe\x72\xfe\xb1\xde\x80\xa7\x06\xdc\x9b\x74\xf1\x9b\xc1\xc1\x69\x9b\xe4\x86\x47\xbe\xef\xc6\x9d\xc1\x0f\xcc\xa1\x0c\x24\x6f\x2c\xe9\x2d\xaa\x84\x74\x4a\xdc\xa9\xb0\x5c\xda\x88\xf9\x76\x52\x51\x3e\x98\x6d\xc6\x31\xa8\xc8\x27\x03\xb0\xc7\x7f\x59\xbf\xf3\x0b\xe0\xc6\x47"]],
["RawDES_Spbox",["\x00\x04\x01\x01\x00\x00\x00\x00\x00\x00\x01\x00\x04\x04\x01\x01\x04\x00\x01\x01\x04\x04\x01\x00\x04\x00\x00\x00\x00\x00\x01\x00\x00\x04\x00\x00\x00\x04\x01\x01\x04\x04\x01\x01\x00\x04\x00\x00\x04\x04\x00\x01\x04\x00\x01\x01\x00\x00\x00\x01\x04\x00\x00\x00\x04\x04\x00\x00\x00\x04\x00\x01\x00\x04\x00\x01\x00\x04\x01\x00\x00\x04\x01\x00\x00\x00\x01\x01\x00\x00\x01\x01\x04\x04\x00\x01\x04\x00\x01\x00\x04\x00\x00\x01\x04\x00\x00\x01\x04\x00\x01\x00\x00\x00\x00\x00"]],
["TIGER_table",["\x5e\x0c\xe9\xf7\x7c\xb1\xaa\x02\xec\xa8\x43\xe2\x03\x4b\x42\xac\xd3\xfc\xd5\x0d\xe3\x5b\xcd\x72\x3a\x7f\xf9\xf6\x93\x9b\x01\x6d\x93\x91\x1f\xd2\xff\x78\x99\xcd\xe2\x29\x80\x70\xc9\xa1\x73\x75\xc3\x83\x2a\x92\x6b\x32\x64\xb1\x70\x58\x91\x04\xee\x3e\x88\x46\xe6\xec\x03\x71\x05\xe3\xac\xea\x5c\x53\xa3\x08\xb8\x69\x41\xc5\x7c\xc4\xde\x8d\x91\x54\xe7\x4c\x0c\xf4\x0d\xdc\xdf\xf4\xa2\x0a\xfa\xbe\x4d\xa7\x18\x6f\xb7\x10\x6a\xab\xd1\x5a\x23\xb6\xcc\xc6\xff\xe2\x2f"]],
["PKCS_md5",["\x30\x20\x30\x0c\x06\x08\x2a\x86\x48\x86\xf7\x0d\x02\x05\x05\x00\x04\x10"]],
["SQUARE_encryption_table",["\x26\xb1\xb1\x97\xa7\xce\xce\x69\xb0\xc3\xc3\x73\x4a\x95\x95\xdf\xee\x5a\x5a\xb4\x02\xad\xad\xaf\xdc\xe7\xe7\x3b\x06\x02\x02\x04\xd7\x4d\x4d\x9a\xcc\x44\x44\x88\xf8\xfb\xfb\x03\x46\x91\x91\xd7\x14\x0c\x0c\x18\x7c\x87\x87\xfb\x16\xa1\xa1\xb7\xf0\x50\x50\xa0\xa8\xcb\xcb\x63\xa9\x67\x67\xce\xfc\x54\x54\xa8\x92\xdd\xdd\x4f\xca\x46\x46\x8c\x64\x8f\x8f\xeb\xd6\xe1\xe1\x37\xd2\x4e\x4e\x9c\xe5\xf0\xf0\x15\xf2\xfd\xfd\x0f\xf1\xfc\xfc\x0d\xc8\xeb\xeb\x23\xfe\xf9"]],
["DES_pc2",["\x0e\x11\x0b\x18\x01\x05\x03\x1c\x0f\x06\x15\x0a\x17\x13\x0c\x04\x1a\x08\x10\x07\x1b\x14\x0d\x02\x29\x34\x1f\x25\x2f\x37\x1e\x28\x33\x2d\x21\x30\x2c\x31\x27\x38\x22\x35\x2e\x2a\x32\x24\x1d\x20"]],
["DES_p32i",["\x10\x07\x14\x15\x1d\x0c\x1c\x11\x01\x0f\x17\x1a\x05\x12\x1f\x0a\x02\x08\x18\x0e\x20\x1b\x03\x09\x13\x0d\x1e\x06\x16\x0b\x04\x19"]],
["SHARK_iG",["\xe7\x30\x90\x85\xd0\x4b\x91\x41\x53\x95\x9b\xa5\x96\xbc\xa1\x68\x02\x45\xf7\x65\x5c\x1f\xb6\x52\xa2\xca\x22\x94\x44\x63\x2a\xa2\xfc\x67\x8e\x10\x29\x75\x85\x71\x24\x45\xa2\xcf\x2f\x22\xc1\x0e\xa1\xf1\x71\x40\x91\x27\x18\xa5\x56\xf4\xaf\x32\xd2\xa4\xdc\x71"]],
["DES_Sboxes",["\x0e\x04\x0d\x01\x02\x0f\x0b\x08\x03\x0a\x06\x0c\x05\x09\x00\x07\x00\x0f\x07\x04\x0e\x02\x0d\x01\x0a\x06\x0c\x0b\x09\x05\x03\x08\x04\x01\x0e\x08\x0d\x06\x02\x0b\x0f\x0c\x09\x07\x03\x0a\x05\x00\x0f\x0c\x08\x02\x04\x09\x01\x07\x05\x0b\x03\x0e\x0a\x00\x06\x0d\x0f\x01\x08\x0e\x06\x0b\x03\x04\x09\x07\x02\x0d\x0c\x00\x05\x0a\x03\x0d\x04\x07\x0f\x02\x08\x0e\x0c\x00\x01\x0a\x06\x09\x0b\x05\x00\x0e\x07\x0b\x0a\x04\x0d\x01\x05\x08\x0c\x06\x09\x03\x02\x0f\x0d\x08\x0a\x01"]],
["whirlpool_c3",["\x78\x18\x28\x18\x18\x78\xd8\xc0\xaf\x23\x65\x23\x23\xaf\x26\x05\xf9\xc6\x57\xc6\xc6\xf9\xb8\x7e\x6f\xe8\x25\xe8\xe8\x6f\xfb\x13\xa1\x87\x94\x87\x87\xa1\xcb\x4c\x62\xb8\xd5\xb8\xb8\x62\x11\xa9\x05\x01\x03\x01\x01\x05\x09\x08\x6e\x4f\xd1\x4f\x4f\x6e\x0d\x42\xee\x36\x5a\x36\x36\xee\x9b\xad\x04\xa6\xf7\xa6\xa6\x04\xff\x59\xbd\xd2\x6b\xd2\xd2\xbd\x0c\xde\x06\xf5\x02\xf5\xf5\x06\x0e\xfb\x80\x79\x8b\x79\x79\x80\x96\xef\xce\x6f\xb1\x6f\x6f\xce\x30\x5f\xef\x91\xae\x91\x91\xef\x6d"]],
["rijndael_te4",["\x63\x63\x63\x63\x7c\x7c\x7c\x7c\x77\x77\x77\x77\x7b\x7b\x7b\x7b\xf2\xf2\xf2\xf2\x6b\x6b\x6b\x6b\x6f\x6f\x6f\x6f\xc5\xc5\xc5\xc5\x30\x30\x30\x30\x01\x01\x01\x01\x67\x67\x67\x67\x2b\x2b\x2b\x2b\xfe\xfe\xfe\xfe\xd7\xd7\xd7\xd7\xab\xab\xab\xab\x76\x76\x76\x76\xca\xca\xca\xca\x82\x82\x82\x82\xc9\xc9\xc9\xc9\x7d\x7d\x7d\x7d\xfa\xfa\xfa\xfa\x59\x59\x59\x59\x47\x47\x47\x47\xf0\xf0\xf0\xf0\xad\xad\xad\xad\xd4\xd4\xd4\xd4\xa2\xa2\xa2\xa2\xaf\xaf\xaf\xaf\x9c\x9c\x9c"]],
["whirlpool_c0",["\x78\xd8\xc0\x78\x18\x28\x18\x18\xaf\x26\x05\xaf\x23\x65\x23\x23\xf9\xb8\x7e\xf9\xc6\x57\xc6\xc6\x6f\xfb\x13\x6f\xe8\x25\xe8\xe8\xa1\xcb\x4c\xa1\x87\x94\x87\x87\x62\x11\xa9\x62\xb8\xd5\xb8\xb8\x05\x09\x08\x05\x01\x03\x01\x01\x6e\x0d\x42\x6e\x4f\xd1\x4f\x4f\xee\x9b\xad\xee\x36\x5a\x36\x36\x04\xff\x59\x04\xa6\xf7\xa6\xa6\xbd\x0c\xde\xbd\xd2\x6b\xd2\xd2\x06\x0e\xfb\x06\xf5\x02\xf5\xf5\x80\x96\xef\x80\x79\x8b\x79\x79\xce\x30\x5f\xce\x6f\xb1\x6f\x6f\xef\x6d\xfc"]],
["rijndael_te3",["\xc6\xa5\x63\x63\xf8\x84\x7c\x7c\xee\x99\x77\x77\xf6\x8d\x7b\x7b\xff\x0d\xf2\xf2\xd6\xbd\x6b\x6b\xde\xb1\x6f\x6f\x91\x54\xc5\xc5\x60\x50\x30\x30\x02\x03\x01\x01\xce\xa9\x67\x67\x56\x7d\x2b\x2b\xe7\x19\xfe\xfe\xb5\x62\xd7\xd7\x4d\xe6\xab\xab\xec\x9a\x76\x76\x8f\x45\xca\xca\x1f\x9d\x82\x82\x89\x40\xc9\xc9\xfa\x87\x7d\x7d\xef\x15\xfa\xfa\xb2\xeb\x59\x59\x8e\xc9\x47\x47\xfb\x0b\xf0\xf0\x41\xec\xad\xad\xb3\x67\xd4\xd4\x5f\xfd\xa2\xa2\x45\xea\xaf\xaf"]],
["camellia_s",["\x70\x82\x2c\xec\xb3\x27\xc0\xe5\xe4\x85\x57\x35\xea\x0c\xae\x41\x23\xef\x6b\x93\x45\x19\xa5\x21\xed\x0e\x4f\x4e\x1d\x65\x92\xbd\x86\xb8\xaf\x8f\x7c\xeb\x1f\xce\x3e\x30\xdc\x5f\x5e\xc5\x0b\x1a\xa6\xe1\x39\xca\xd5\x47\x5d\x3d\xd9\x01\x5a\xd6\x51\x56\x6c\x4d\x8b\x0d\x9a\x66\xfb\xcc\xb0\x2d\x74\x12\x2b\x20\xf0\xb1\x84\x99\xdf\x4c\xcb\xc2\x34\x7e\x76\x05\x6d\xb7\xa9\x31\xd1\x17\x04\xd7\x14\x58\x3a\x61\xde\x1b\x11\x1c\x32\x0f\x9c\x16\x53"]],
["CRC32",["\x00\x00\x00\x00\x96\x30\x07\x77\x2c\x61\x0e\xee\xba\x51\x09\x99\x19\xc4\x6d\x07\x8f\xf4\x6a\x70\x35\xa5\x63\xe9\xa3\x95\x64\x9e\x32\x88\xdb\x0e\xa4\xb8\xdc\x79\x1e\xe9\xd5\xe0\x88\xd9\xd2\x97\x2b\x4c\xb6\x09\xbd\x7c\xb1\x7e\x07\x2d\xb8\xe7\x91\x1d\xbf\x90\x64\x10\xb7\x1d\xf2\x20\xb0\x6a\x48\x71\xb9\xf3\xde\x41\xbe\x84\x7d\xd4\xda\x1a\xeb\xe4\xdd\x6d\x51\xb5\xd4\xf4\xc7\x85\xd3\x83\x56\x98\x6c\x13\xc0\xa8\x6b\x64\x7a\xf9\x62\xfd\xec\xc9\x65\x8a\x4f"]],
["rijndael_td1",["\xa7\xf4\x51\x50\x65\x41\x7e\x53\xa4\x17\x1a\xc3\x5e\x27\x3a\x96\x6b\xab\x3b\xcb\x45\x9d\x1f\xf1\x58\xfa\xac\xab\x03\xe3\x4b\x93\xfa\x30\x20\x55\x6d\x76\xad\xf6\x76\xcc\x88\x91\x4c\x02\xf5\x25\xd7\xe5\x4f\xfc\xcb\x2a\xc5\xd7\x44\x35\x26\x80\xa3\x62\xb5\x8f\x5a\xb1\xde\x49\x1b\xba\x25\x67\x0e\xea\x45\x98\xc0\xfe\x5d\xe1\x75\x2f\xc3\x02\xf0\x4c\x81\x12\x97\x46\x8d\xa3\xf9\xd3\x6b\xc6\x5f\x8f\x03\xe7\x9c\x92\x15\x95\x7a\x6d\xbf\xeb\x59\x52\x95\xda\x83\xbe\xd4"]],
["Twofish_q",["\xa9\x67\xb3\xe8\x04\xfd\xa3\x76\x9a\x92\x80\x78\xe4\xdd\xd1\x38\x0d\xc6\x35\x98\x18\xf7\xec\x6c\x43\x75\x37\x26\xfa\x13\x94\x48\xf2\xd0\x8b\x30\x84\x54\xdf\x23\x19\x5b\x3d\x59\xf3\xae\xa2\x82\x63\x01\x83\x2e\xd9\x51\x9b\x7c\xa6\xeb\xa5\xbe\x16\x0c\xe3\x61\xc0\x8c\x3a\xf5\x73\x2c\x25\x0b\xbb\x4e\x89\x6b\x53\x6a\xb4\xf1\xe1\xe6\xbd\x45\xe2\xf4\xb6\x66\xcc\x95\x03\x56\xd4\x1c\x1e\xd7\xfb\xc3\x8e\xb5\xe9\xcf\xbf\xba\xea\x77\x39\xaf\x33\xc9\x62\x71"]],
["DES_ip",["\x3a\x32\x2a\x22\x1a\x12\x0a\x02\x3c\x34\x2c\x24\x1c\x14\x0c\x04\x3e\x36\x2e\x26\x1e\x16\x0e\x06\x40\x38\x30\x28\x20\x18\x10\x08\x39\x31\x29\x21\x19\x11\x09\x01\x3b\x33\x2b\x23\x1b\x13\x0b\x03\x3d\x35\x2d\x25\x1d\x15\x0d\x05\x3f\x37\x2f\x27\x1f\x17\x0f\x07"]],
["whirlpool_c1",["\xd8\xc0\x78\x18\x28\x18\x18\x78\x26\x05\xaf\x23\x65\x23\x23\xaf\xb8\x7e\xf9\xc6\x57\xc6\xc6\xf9\xfb\x13\x6f\xe8\x25\xe8\xe8\x6f\xcb\x4c\xa1\x87\x94\x87\x87\xa1\x11\xa9\x62\xb8\xd5\xb8\xb8\x62\x09\x08\x05\x01\x03\x01\x01\x05\x0d\x42\x6e\x4f\xd1\x4f\x4f\x6e\x9b\xad\xee\x36\x5a\x36\x36\xee\xff\x59\x04\xa6\xf7\xa6\xa6\x04\x0c\xde\xbd\xd2\x6b\xd2\xd2\xbd\x0e\xfb\x06\xf5\x02\xf5\xf5\x06\x96\xef\x80\x79\x8b\x79\x79\x80\x30\x5f\xce\x6f"]],
["whirlpool_rc",["\x4f\x01\xb8\x87\xe8\xc6\x23\x18\x52\x91\x6f\x79\xf5\xd2\xa6\x36\x35\x7b\x0c\xa3\x8e\x9b\xbc\x60\x57\xfe\x4b\x2e\xc2\xd7\xe0\x1d\xda\x4a\xf0\x9f\xe5\x37\x77\x15\x85\x6b\xa0\xb1\x0a\x29\xc9\x58\x67\x05\x3e\xcb\xf4\x10\x5d\xbd\xd8\x95\x7d\xa7\x8b\x41\x27\xe4\x9e\x47\x17\xdd\x66\x7c\xee\xfb\x33\x83\x5a\xad\x07\xbf\x2d\xca"]],
["rijndael_te1",["\x63\x63\xc6\xa5\x7c\x7c\xf8\x84\x77\x77\xee\x99\x7b\x7b\xf6\x8d\xf2\xf2\xff\x0d\x6b\x6b\xd6\xbd\x6f\x6f\xde\xb1\xc5\xc5\x91\x54\x30\x30\x60\x50\x01\x01\x02\x03\x67\x67\xce\xa9\x2b\x2b\x56\x7d\xfe\xfe\xe7\x19\xd7\xd7\xb5\x62\xab\xab\x4d\xe6\x76\x76\xec\x9a\xca\xca\x8f\x45\x82\x82\x1f\x9d\xc9\xc9\x89\x40\x7d\x7d\xfa\x87\xfa\xfa\xef\x15\x59\x59\xb2\xeb\x47\x47\x8e\xc9\xf0\xf0\xfb\x0b\xad\xad\x41\xec\xd4\xd4\xb3\x67\xa2\xa2\x5f\xfd\xaf\xaf\x45\xea"]],
["Blowfish_s_init",["\xa6\x0b\x31\xd1\xac\xb5\xdf\x98\xdb\x72\xfd\x2f\xb7\xdf\x1a\xd0\xed\xaf\xe1\xb8\x96\x7e\x26\x6a\x45\x90\x7c\xba\x99\x7f\x2c\xf1\x47\x99\xa1\x24\xf7\x6c\x91\xb3\xe2\xf2\x01\x08\x16\xfc\x8e\x85\xd8\x20\x69\x63\x69\x4e\x57\x71\xa3\xfe\x58\xa4\x7e\x3d\x93\xf4\x8f\x74\x95\x0d\x58\xb6\x8e\x72\x58\xcd\x8b\x71\xee\x4a\x15\x82\x1d\xa4\x54\x7b\xb5\x59\x5a\xc2\x39\xd5\x30\x9c\x13\x60\xf2\x2a\x23\xb0\xd1\xc5\xf0\x85\x60\x28\x18\x79\x41"]],
["SAFER_exp_table",["\x01\x2d\xe2\x93\xbe\x45\x15\xae\x78\x03\x87\xa4\xb8\x38\xcf\x3f\x08\x67\x09\x94\xeb\x26\xa8\x6b\xbd\x18\x34\x1b\xbb\xbf\x72\xf7\x40\x35\x48\x9c\x51\x2f\x3b\x55\xe3\xc0\x9f\xd8\xd3\xf3\x8d\xb1\xff\xa7\x3e\xdc\x86\x77\xd7\xa6\x11\xfb\xf4\xba\x92\x91\x64\x83\xf1\x33\xef\xda\x2c\xb5\xb2\x2b\x88\xd1\x99\xcb\x8c\x84\x1d\x14\x81\x97\x71\xca\x5f\xa3\x8b\x57\x3c\x82\xc4\x52\x5c\x1c\xe8\xa0\x04\xb4\x85\x4a\xf6\x13\x54\xb6\xdf\x0c\x1a"]],
["SQUARE_decryption_table",["\x02\xbc\x68\xe3\x0c\x62\x85\x55\x31\x23\x3f\x2a\xf7\x13\xab\x61\x72\x6d\xd4\x98\x19\x9a\xcb\x21\x61\xa4\x22\x3c\xcd\x3d\x9d\x45\x23\xb4\xfd\x05\x5f\x07\xc4\x2b\xc0\x01\x2c\x9b\x0f\x80\xd9\x3d\x74\x5c\x6c\x48\x85\x7e\x7f\xf9\x1f\xab\x73\xf1\x0e\xde\xed\xb6\xed\x6b\x3c\x28\x1a\x78\x97\x49\x8d\x91\x2a\x9f\x33\x9f\x57\xc9\xaa\xa8\x07\xa9\x7d\xed\x0d\xa5\x8f\x2d\x42\x7c\xc9\xb0\x4d\x76\x57\xe8\x91\x4d\xcc\x63\xa9"]],
["rijndael_td2",["\xf4\x51\x50\xa7\x41\x7e\x53\x65\x17\x1a\xc3\xa4\x27\x3a\x96\x5e\xab\x3b\xcb\x6b\x9d\x1f\xf1\x45\xfa\xac\xab\x58\xe3\x4b\x93\x03\x30\x20\x55\xfa\x76\xad\xf6\x6d\xcc\x88\x91\x76\x02\xf5\x25\x4c\xe5\x4f\xfc\xd7\x2a\xc5\xd7\xcb\x35\x26\x80\x44\x62\xb5\x8f\xa3\xb1\xde\x49\x5a\xba\x25\x67\x1b\xea\x45\x98\x0e\xfe\x5d\xe1\xc0\x2f\xc3\x02\x75\x4c\x81\x12\xf0\x46\x8d\xa3\x97\xd3\x6b\xc6\xf9\x8f\x03\xe7\x5f\x92\x15\x95\x9c\x6d\xbf\xeb\x7a\x52\x95"]],
["CAST256_t_r",["\x13\x00\x00\x00\x1b\x00\x00\x00\x03\x00\x00\x00\x0b\x00\x00\x00\x13\x00\x00\x00\x1b\x00\x00\x00\x03\x00\x00\x00\x0b\x00\x00\x00\x13\x00\x00\x00\x1b\x00\x00\x00\x03\x00\x00\x00\x0b\x00\x00\x00\x13\x00\x00\x00\x1b\x00\x00\x00\x03\x00\x00\x00\x0b\x00\x00\x00\x13\x00\x00\x00\x1b\x00\x00\x00\x03\x00\x00\x00\x0b\x00\x00\x00\x13\x00\x00\x00\x1b\x00\x00\x00\x03\x00\x00\x00\x0b\x00\x00\x00\x04\x00\x00\x00\x0c\x00\x00\x00\x14\x00"]],
["rijndael_te0",["\xa5\x63\x63\xc6\x84\x7c\x7c\xf8\x99\x77\x77\xee\x8d\x7b\x7b\xf6\x0d\xf2\xf2\xff\xbd\x6b\x6b\xd6\xb1\x6f\x6f\xde\x54\xc5\xc5\x91\x50\x30\x30\x60\x03\x01\x01\x02\xa9\x67\x67\xce\x7d\x2b\x2b\x56\x19\xfe\xfe\xe7\x62\xd7\xd7\xb5\xe6\xab\xab\x4d\x9a\x76\x76\xec\x45\xca\xca\x8f\x9d\x82\x82\x1f\x40\xc9\xc9\x89\x87\x7d\x7d\xfa\x15\xfa\xfa\xef\xeb\x59\x59\xb2\xc9\x47\x47\x8e\x0b\xf0\xf0\xfb\xec\xad\xad\x41\x67\xd4\xd4\xb3\xfd\xa2\xa2"]],
["SKIPJACK_fTable",["\xa3\xd7\x09\x83\xf8\x48\xf6\xf4\xb3\x21\x15\x78\x99\xb1\xaf\xf9\xe7\x2d\x4d\x8a\xce\x4c\xca\x2e\x52\x95\xd9\x1e\x4e\x38\x44\x28\x0a\xdf\x02\xa0\x17\xf1\x60\x68\x12\xb7\x7a\xc3\xe9\xfa\x3d\x53\x96\x84\x6b\xba\xf2\x63\x9a\x19\x7c\xae\xe5\xf5\xf7\x16\x6a\xa2\x39\xb6\x7b\x0f\xc1\x93\x81\x1b\xee\xb4\x1a\xea\xd0\x91\x2f\xb8\x55\xb9\xda\x85\x3f\x41\xbf\xe0\x5a\x58\x80\x5f\x66\x0b\xd8\x90\x35\xd5\xc0\xa7\x33\x06\x65\x69\x45"]],
["HAVAL_mc2",["\xe6\x21\x28\x45\x77\x13\xd0\x38\xcf\x66\x54\xbe\x6c\x0c\xe9\x34\xb7\x29\xac\xc0\xdd\x50\x7c\xc9\xb5\xd5\x84\x3f\x17\x09\x47\xb5\xd9\xd5\x16\x92\x1b\xfb\x79\x89\xa6\x0b\x31\xd1\xac\xb5\xdf\x98\xdb\x72\xfd\x2f\xb7\xdf\x1a\xd0\xed\xaf\xe1\xb8\x96\x7e\x26\x6a\x45\x90\x7c\xba\x99\x7f\x2c\xf1\x47\x99\xa1\x24\xf7\x6c\x91\xb3\xe2\xf2\x01\x08\x16\xfc\x8e\x85\xd8\x20\x69\x63\x69\x4e\x57\x71\xa3\xfe\x58\xa4\x7e\x3d\x93\xf4\x8f\x74\x95\x0d\x58\xb6\x8e\x72\x58\xcd\x8b\x71\xee\x4a\x15\x82\x1d\xa4\x54\x7b\xb5\x59\x5a\xc2"]],
["CAST_S",["\xd4\x40\xfb\x30\x0b\xff\xa0\x9f\x2f\xcd\xec\x6b\x7a\x8c\x25\x3f\x2f\x3f\x21\x1e\xd3\x4d\x00\x9c\x40\xe5\x03\x60\x49\xc9\x9f\xcf\x27\xaf\xd4\xbf\xb5\xbd\xbb\x88\x90\x40\x03\xe2\x75\x96\xd0\x98\xe0\xa0\x63\x6e\xd2\x61\xc3\x15\x1d\x66\xe7\xc2\x8e\xff\xd4\x22\x6f\x3b\x68\x28\x59\xd0\x7f\xc0\xc8\x79\x23\xff\xe2\x50\x5f\x77\xd3\x40\xc3\x43\x56\x86\x2f\xdf\x1a\xa4\x7c\x88\x2d\xbd\xd2\xa2\xd6\xe0\xc9\xa1\x19\x48"]],
["HAVAL_wi3",["\x13\x00\x00\x00\x09\x00\x00\x00\x04\x00\x00\x00\x14\x00\x00\x00\x1c\x00\x00\x00\x11\x00\x00\x00\x08\x00\x00\x00\x16\x00\x00\x00\x1d\x00\x00\x00\x0e\x00\x00\x00\x19\x00\x00\x00\x0c\x00\x00\x00\x18\x00\x00\x00\x1e\x00\x00\x00\x10\x00\x00\x00\x1a\x00\x00\x00\x1f\x00\x00\x00\x0f\x00\x00\x00\x07\x00\x00\x00\x03\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x12\x00\x00\x00\x1b\x00\x00\x00\x0d\x00\x00\x00\x06\x00\x00\x00\x15\x00\x00\x00\x0a\x00\x00\x00\x17\x00\x00\x00\x0b\x00\x00\x00\x05\x00\x00\x00\x02\x00\x00\x00"]],
["CAST256_t_m",["\x99\x79\x82\x5a\xa1\xd6\x51\xd1\xa9\x33\x21\x48\xb1\x90\xf0\xbe\xb9\xed\xbf\x35\xc1\x4a\x8f\xac\xc9\xa7\x5e\x23\xd1\x04\x2e\x9a\xd9\x61\xfd\x10\xe1\xbe\xcc\x87\xe9\x1b\x9c\xfe\xf1\x78\x6b\x75\xf9\xd5\x3a\xec\x01\x33\x0a\x63\x09\x90\xd9\xd9\x11\xed\xa8\x50\x19\x4a\x78\xc7\x21\xa7\x47\x3e\x29\x04\x17\xb5\x31\x61\xe6\x2b\x39\xbe\xb5\xa2\x41\x1b\x85\x19\x49\x78\x54\x90\x51\xd5\x23\x07\x3a\x65\x5c\xc9\x42\xc2\x2b\x40\x4a"]],
["DES_fp",["\x28\x08\x30\x10\x38\x18\x40\x20\x27\x07\x2f\x0f\x37\x17\x3f\x1f\x26\x06\x2e\x0e\x36\x16\x3e\x1e\x25\x05\x2d\x0d\x35\x15\x3d\x1d\x24\x04\x2c\x0c\x34\x14\x3c\x1c\x23\x03\x2b\x0b\x33\x13\x3b\x1b\x22\x02\x2a\x0a\x32\x12\x3a\x1a\x21\x01\x29\x09\x31\x11\x39\x19"]],
["SHARK_decrpytion_cbox",["\xf3\xaf\x55\x5e\xf0\x6a\x12\xe6\x35\x08\x0b\x31\x3f\x89\x6c\x4b\x57\x8d\xfc\xeb\x84\x0e\x4c\xaa\x0d\x09\xb3\xf3\x7b\x5c\x9b\xfb\xe2\x5c\xba\xcc\xa9\xa6\x08\x45\xe9\xbd\xc6\x4d\x06\xd2\xd1\xe5\xde\xed\x88\x52\x75\x43\x83\x34\x0c\x25\x6b\xe4\x5d\x50\x84\xb6\xe8\x91\x1e\x5a\x20\xde\xce\xa8\xcc\x6a\xfa\xf9\x46\x9b\xb8\x40\xba\x80\xb0\xfa\x1a\xec\xe1\x8e\x45\x0a\x8e\x40\xb7\xd6\x77\xde\x02\x58\x45\x2e\x4c\x18\x3e\x9a"]],
["SAFER_log_table",["\x80\x00\xb0\x09\x60\xef\xb9\xfd\x10\x12\x9f\xe4\x69\xba\xad\xf8\xc0\x38\xc2\x65\x4f\x06\x94\xfc\x19\xde\x6a\x1b\x5d\x4e\xa8\x82\x70\xed\xe8\xec\x72\xb3\x15\xc3\xff\xab\xb6\x47\x44\x01\xac\x25\xc9\xfa\x8e\x41\x1a\x21\xcb\xd3\x0d\x6e\xfe\x26\x58\xda\x32\x0f\x20\xa9\x9d\x84\x98\x05\x9c\xbb\x22\x8c\x63\xe7\xc5\xe1\x73\xc6\xaf\x24\x5b\x87\x66\x27\xf7\x57\xf4\x96\xb1\xb7\x5c\x8b\xd5\x54\x79\xdf\xaa\xf6\x3e\xa3"]],
["whirlpool_c2",["\xc0\x78\x18\x28\x18\x18\x78\xd8\x05\xaf\x23\x65\x23\x23\xaf\x26\x7e\xf9\xc6\x57\xc6\xc6\xf9\xb8\x13\x6f\xe8\x25\xe8\xe8\x6f\xfb\x4c\xa1\x87\x94\x87\x87\xa1\xcb\xa9\x62\xb8\xd5\xb8\xb8\x62\x11\x08\x05\x01\x03\x01\x01\x05\x09\x42\x6e\x4f\xd1\x4f\x4f\x6e\x0d\xad\xee\x36\x5a\x36\x36\xee\x9b\x59\x04\xa6\xf7\xa6\xa6\x04\xff\xde\xbd\xd2\x6b\xd2\xd2\xbd\x0c\xfb\x06\xf5\x02\xf5\xf5\x06\x0e\xef\x80\x79\x8b\x79\x79"]],
["PKCS_md2",["\x30\x20\x30\x0c\x06\x08\x2a\x86\x48\x86\xf7\x0d\x02\x02\x05\x00\x04\x10"]],
["HAVAL_mc3",["\x39\xd5\x30\x9c\x13\x60\xf2\x2a\x23\xb0\xd1\xc5\xf0\x85\x60\x28\x18\x79\x41\xca\xef\x38\xdb\xb8\xb0\xdc\x79\x8e\x0e\x18\x3a\x60\x8b\x0e\x9e\x6c\x3e\x8a\x1e\xb0\xc1\x77\x15\xd7\x27\x4b\x31\xbd\xda\x2f\xaf\x78\x60\x5c\x60\x55\xf3\x25\x55\xe6\x94\xab\x55\xaa\x62\x98\x48\x57\x40\x14\xe8\x63\x6a\x39\xca\x55\xb6\x10\xab\x2a\x34\x5c\xcc\xb4\xce\xe8\x41\x11\xaf\x86\x54\xa1\x93\xe9\x72\x7c\x11\x14\xee\xb3\x2a\xbc\x6f\x63\x5d\xc5\xa9\x2b\xf6\x31\x18\x74\x16\x3e\x5c\xce\x1e\x93\x87\x9b\x33\xba\xd6\xaf\x5c\xcf\x24\x6c"]],
["rijndael_te2",["\x63\xc6\xa5\x63\x7c\xf8\x84\x7c\x77\xee\x99\x77\x7b\xf6\x8d\x7b\xf2\xff\x0d\xf2\x6b\xd6\xbd\x6b\x6f\xde\xb1\x6f\xc5\x91\x54\xc5\x30\x60\x50\x30\x01\x02\x03\x01\x67\xce\xa9\x67\x2b\x56\x7d\x2b\xfe\xe7\x19\xfe\xd7\xb5\x62\xd7\xab\x4d\xe6\xab\x76\xec\x9a\x76\xca\x8f\x45\xca\x82\x1f\x9d\x82\xc9\x89\x40\xc9\x7d\xfa\x87\x7d\xfa\xef\x15\xfa\x59\xb2\xeb\x59\x47\x8e\xc9\x47\xf0\xfb\x0b\xf0\xad\x41\xec\xad\xd4\xb3\x67\xd4\xa2\x5f"]],
["WAKE_tt",["\x3b\x8f\x6a\x72\x5c\x3b\x9a\xe6\xe5\x1f\xc7\xd3\xd2\x73\x3c\xab\xb3\x8e\x3a\x4d\xe8\xd6\x96\x03\x7a\x2f\x4c\x3d\xf3\x7c\xe2\x9e"]],
["DES_pc1",["\x39\x31\x29\x21\x19\x11\x09\x01\x3a\x32\x2a\x22\x1a\x12\x0a\x02\x3b\x33\x2b\x23\x1b\x13\x0b\x03\x3c\x34\x2c\x24\x3f\x37\x2f\x27\x1f\x17\x0f\x07\x3e\x36\x2e\x26\x1e\x16\x0e\x06\x3d\x35\x2d\x25\x1d\x15\x0d\x05\x1c\x14\x0c\x04"]],
["zinflate_distanceStarts",["\x01\x00\x00\x00\x02\x00\x00\x00\x03\x00\x00\x00\x04\x00\x00\x00\x05\x00\x00\x00\x07\x00\x00\x00\x09\x00\x00\x00\x0d\x00\x00\x00\x11\x00\x00\x00\x19\x00\x00\x00\x21\x00\x00\x00\x31\x00\x00\x00\x41\x00\x00\x00\x61\x00\x00\x00\x81\x00\x00\x00\xc1\x00\x00\x00\x01\x01\x00\x00\x81\x01\x00\x00\x01\x02\x00\x00\x01\x03\x00\x00\x01\x04\x00\x00\x01\x06\x00\x00\x01\x08\x00\x00\x01\x0c\x00\x00\x01\x10\x00\x00\x01\x18\x00\x00\x01\x20\x00\x00\x01\x30\x00\x00\x01\x40\x00\x00\x01\x60\x00\x00"]],
["HAVAL_mc4",["\x81\x53\x32\x7a\x77\x86\x95\x28\x98\x48\x8f\x3b\xaf\xb9\x4b\x6b\x1b\xe8\xbf\xc4\x93\x21\x28\x66\xcc\x09\xd8\x61\x91\xa9\x21\xfb\x60\xac\x7c\x48\x32\x80\xec\x5d\x5d\x5d\x84\xef\xb1\x75\x85\xe9\x02\x23\x26\xdc\x88\x1b\x65\xeb\x81\x3e\x89\x23\xc5\xac\x96\xd3\xf3\x6f\x6d\x0f\x39\x42\xf4\x83\x82\x44\x0b\x2e\x04\x20\x84\xa4\x4a\xf0\xc8\x69\x5e\x9b\x1f\x9e\x42\x68\xc6\x21\x9a\x6c\xe9\xf6\x61\x9c\x0c\x67\xf0\x88\xd3\xab\xd2\xa0\x51\x6a\x68\x2f\x54\xd8\x28\xa7\x0f\x96\xa3\x33\x51\xab\x6c\x0b\xef\x6e\xe4\x3b\x7a\x13"]],
["Square/SHARK_decryption_SBOX",["\x35\xbe\x07\x2e\x53\x69\xdb\x28\x6f\xb7\x76\x6b\x0c\x7d\x36\x8b\x92\xbc\xa9\x32\xac\x38\x9c\x42\x63\xc8\x1e\x4f\x24\xe5\xf7\xc9\x61\x8d\x2f\x3f\xb3\x65\x7f\x70\xaf\x9a\xea\xf5\x5b\x98\x90\xb1\x87\x71\x72\xed\x37\x45\x68\xa3\xe3\xef\x5c\xc5\x50\xc1\xd6\xca\x5a\x62\x5f\x26\x09\x5d\x14\x41\xe8\x9d\xce\x40\xfd\x08\x17\x4a\x0f\xc7\xb4\x3e\x12\xfc\x25\x4b\x81\x2c\x04\x78\xcb\xbb\x20\xbd\xf9\x29\x99\xa8\xd3\x60\xdf\x11"]],
["SAFER_exponent_table",["\x01\x2d\xe2\x93\xbe\x45\x15\xae\x78\x03\x87\xa4\xb8\x38\xcf\x3f\x08\x67\x09\x94\xeb\x26\xa8\x6b\xbd\x18\x34\x1b\xbb\xbf\x72\xf7\x40\x35\x48\x9c\x51\x2f\x3b\x55\xe3\xc0\x9f\xd8\xd3\xf3\x8d\xb1\xff\xa7\x3e\xdc\x86\x77\xd7\xa6\x11\xfb\xf4\xba\x92\x91\x64\x83\xf1\x33\xef\xda\x2c\xb5\xb2\x2b\x88\xd1\x99\xcb\x8c\x84\x1d\x14\x81\x97\x71\xca\x5f\xa3\x8b\x57\x3c\x82\xc4\x52\x5c\x1c\xe8\xa0\x04\xb4\x85\x4a\xf6\x13\x54"]],
["SKIPJACK_F-table",["\xa3\xd7\x09\x83\xf8\x48\xf6\xf4\xb3\x21\x15\x78\x99\xb1\xaf\xf9\xe7\x2d\x4d\x8a\xce\x4c\xca\x2e\x52\x95\xd9\x1e\x4e\x38\x44\x28\x0a\xdf\x02\xa0\x17\xf1\x60\x68\x12\xb7\x7a\xc3\xe9\xfa\x3d\x53\x96\x84\x6b\xba\xf2\x63\x9a\x19\x7c\xae\xe5\xf5\xf7\x16\x6a\xa2\x39\xb6\x7b\x0f\xc1\x93\x81\x1b\xee\xb4\x1a\xea\xd0\x91\x2f\xb8\x55\xb9\xda\x85\x3f\x41\xbf\xe0\x5a\x58\x80\x5f\x66\x0b\xd8\x90\x35\xd5\xc0\xa7\x33\x06"]],
["Square/SHARK_encryption_SBOX",["\xb1\xce\xc3\x95\x5a\xad\xe7\x02\x4d\x44\xfb\x91\x0c\x87\xa1\x50\xcb\x67\x54\xdd\x46\x8f\xe1\x4e\xf0\xfd\xfc\xeb\xf9\xc4\x1a\x6e\x5e\xf5\xcc\x8d\x1c\x56\x43\xfe\x07\x61\xf8\x75\x59\xff\x03\x22\x8a\xd1\x13\xee\x88\x00\x0e\x34\x15\x80\x94\xe3\xed\xb5\x53\x23\x4b\x47\x17\xa7\x90\x35\xab\xd8\xb8\xdf\x4f\x57\x9a\x92\xdb\x1b\x3c\xc8\x99\x04\x8e\xe0\xd7\x7d\x85\xbb\x40\x2c\x3a\x45\xf1\x42\x65\x20\x41\x18\x72\x25\x93"]],
["rc2_Pi_table",["\xd9\x78\xf9\xc4\x19\xdd\xb5\xed\x28\xe9\xfd\x79\x4a\xa0\xd8\x9d\xc6\x7e\x37\x83\x2b\x76\x53\x8e\x62\x4c\x64\x88\x44\x8b\xfb\xa2\x17\x9a\x59\xf5\x87\xb3\x4f\x13\x61\x45\x6d\x8d\x09\x81\x7d\x32\xbd\x8f\x40\xeb\x86\xb7\x7b\x0b\xf0\x95\x21\x22\x5c\x6b\x4e\x82\x54\xd6\x65\x93\xce\x60\xb2\x1c\x73\x56\xc0\x14\xa7\x8c\xf1\xdc\x12\x75\xca\x1f\x3b\xbe\xe4\xd1\x42\x3d\xd4\x30\xa3\x3c\xb6\x26\x6f\xbf\x0e\xda\x46\x69"]],
["SAFER_logarithm_table",["\x80\x00\xb0\x09\x60\xef\xb9\xfd\x10\x12\x9f\xe4\x69\xba\xad\xf8\xc0\x38\xc2\x65\x4f\x06\x94\xfc\x19\xde\x6a\x1b\x5d\x4e\xa8\x82\x70\xed\xe8\xec\x72\xb3\x15\xc3\xff\xab\xb6\x47\x44\x01\xac\x25\xc9\xfa\x8e\x41\x1a\x21\xcb\xd3\x0d\x6e\xfe\x26\x58\xda\x32\x0f\x20\xa9\x9d\x84\x98\x05\x9c\xbb\x22\x8c\x63\xe7\xc5\xe1\x73\xc6\xaf\x24\x5b\x87\x66\x27\xf7\x57\xf4\x96\xb1\xb7\x5c\x8b\xd5\x54\x79\xdf\xaa\xf6\x3e"]],
["md2",["\x29\x2e\x43\xc9\xa2\xd8\x7c\x01\x3d\x36\x54\xa1\xec\xf0\x06\x13\x62\xa7\x05\xf3\xc0\xc7\x73\x8c\x98\x93\x2b\xd9\xbc\x4c\x82\xca\x1e\x9b\x57\x3c\xfd\xd4\xe0\x16\x67\x42\x6f\x18\x8a\x17\xe5\x12\xbe\x4e\xc4\xd6\xda\x9e\xde\x49\xa0\xfb\xf5\x8e\xbb\x2f\xee\x7a\xa9\x68\x79\x91\x15\xb2\x07\x3f\x94\xc2\x10\x89\x0b\x22\x5f\x21\x80\x7f\x5d\x9a\x5a\x90\x32\x27\x35\x3e\xcc\xe7\xbf\xf7\x97\x03\xff\x19\x30\xb3\x48\xa5\xb5"]],
["ZLIB_length_starts",["\x03\x00\x04\x00\x05\x00\x06\x00\x07\x00\x08\x00\x09\x00\x0a\x00\x0b\x00\x0d\x00\x0f\x00\x11\x00\x13\x00\x17\x00\x1b\x00\x1f\x00\x23\x00\x2b\x00\x33\x00\x3b\x00\x43\x00\x53\x00\x63\x00\x73\x00\x83\x00\xa3\x00\xc3\x00\xe3\x00\x02\x01"]],
["ZLIB_length_extra_bits",["\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x02\x00\x00\x00\x02\x00\x00\x00\x02\x00\x00\x00\x02\x00\x00\x00\x03\x00\x00\x00\x03\x00\x00\x00\x03\x00\x00\x00\x03\x00\x00\x00\x04\x00\x00\x00\x04\x00\x00\x00\x04\x00\x00\x00\x04\x00\x00\x00\x05\x00\x00\x00\x05\x00\x00\x00\x05\x00\x00\x00\x05\x00\x00\x00\x00\x00\x00\x00"]],
["ZLIB_distance_extra_bits",["\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x02\x00\x00\x00\x02\x00\x00\x00\x03\x00\x00\x00\x03\x00\x00\x00\x04\x00\x00\x00\x04\x00\x00\x00\x05\x00\x00\x00\x05\x00\x00\x00\x06\x00\x00\x00\x06\x00\x00\x00\x07\x00\x00\x00\x07\x00\x00\x00\x08\x00\x00\x00\x08\x00\x00\x00\x09\x00\x00\x00\x09\x00\x00\x00\x0a\x00\x00\x00\x0a\x00\x00\x00\x0b\x00\x00\x00\x0b\x00\x00\x00\x0c\x00\x00\x00\x0c\x00\x00\x00\x0d\x00\x00\x00\x0d\x00\x00\x00"]],
["ZLIB_distance_starts",["\x01\x00\x00\x00\x02\x00\x00\x00\x03\x00\x00\x00\x04\x00\x00\x00\x05\x00\x00\x00\x07\x00\x00\x00\x09\x00\x00\x00\x0d\x00\x00\x00\x11\x00\x00\x00\x19\x00\x00\x00\x21\x00\x00\x00\x31\x00\x00\x00\x41\x00\x00\x00\x61\x00\x00\x00\x81\x00\x00\x00\xc1\x00\x00\x00\x01\x01\x00\x00\x81\x01\x00\x00\x01\x02\x00\x00\x01\x03\x00\x00\x01\x04\x00\x00\x01\x06\x00\x00\x01\x08\x00\x00\x01\x0c\x00\x00\x01\x10\x00\x00\x01\x18\x00\x00\x01\x20\x00\x00\x01\x30\x00\x00\x01\x40\x00\x00\x01\x60\x00\x00"]],
["ADLER_32",["\xF1\xFF\x00\x00"]],
["CRC_32_Generator",["\x20\x83\xb8\xed"]],
["TEA/XTEA/XXTEA",["\x47\x86\x68\x61","\xB9\x79\x37\x9E"]],
["XXTEA",["\xa0\x5b\x00\x00\xbb\x82\x00\x00\x59\x01\x00\x00\xc1\x11\x00\x00"]],
["MD6",["\x73\x11\xc2\x81\x24\x25\xcf\xa0\x64\x32\x28\x64\x34\xaa\xc8\xe7\xb6\x04\x50\xe9\xef\x68\xb7\xc1\xe8\xfb\x23\x90\x8d\x9f\x06\xf1\xdd\x2e\x76\xcb\xa6\x91\xe5\xbf\x0c\xd0\xd6\x3b\x2c\x30\xbc\x41\x1f\x8c\xcf\x68\x23\x05\x8f\x8a\x54\xe5\xed\x5b\x88\xe3\x77\x5d\x4a\xd1\x2a\xae\x0a\x6d\x60\x31\x3e\x7f\x16\xbb\x88\x22\x2e\x0d\x8a\xf8\x67\x1d\x3f\xb5\x0c\x2c\x99\x5a\xd1\x17\x8b\xd2\x5c\x31\xc8\x78\xc1\xdd\x04\xc4\xb6\x33\x3b\x72\x06\x6c\x7a\x15\x52\xac\x0d\x6f\x35\x22\x63\x1e\xff\xcb"]],
["md5_T",["\x78\xa4\x6a\xd7\x56\xb7\xc7\xe8\xdb\x70\x20\x24\xee\xce\xbd\xc1\xaf\x0f\x7c\xf5\x2a\xc6\x87\x47\x13\x46\x30\xa8\x01\x95\x46\xfd\xd8\x98\x80\x69\xaf\xf7\x44\x8b\xb1\x5b\xff\xff\xbe\xd7\x5c\x89\x22\x11\x90\x6b\x93\x71\x98\xfd\x8e\x43\x79\xa6\x21\x08\xb4\x49\x62\x25\x1e\xf6\x40\xb3\x40\xc0\x51\x5a\x5e\x26\xaa\xc7\xb6\xe9\x5d\x10\x2f\xd6\x53\x14\x44\x02\x81\xe6\xa1\xd8\xc8\xfb\xd3\xe7\xe6\xcd\xe1\x21\xd6"]],
["sha384_h0",["\x5d\x9d\xbb\xcb\xd8\x9e\x05\xc1\x2a\x29\x9a\x62\x07\xd5\x7c\x36\x5a\x01\x59\x91\x17\xdd\x70\x30\xd8\xec\x2f\x15\x39\x59\x0e\xf7\x67\x26\x33\x67\x31\x0b\xc0\xff\x87\x4a\xb4\x8e\x11\x15\x58\x68\x0d\x2e\x0c\xdb\xa7\x8f\xf9\x64\x1d\x48\xb5\x47\xa4\x4f\xfa\xbe"]],
["sha256_h0",["\x67\xe6\x09\x6a\x85\xae\x67\xbb\x72\xf3\x6e\x3c\x3a\xf5\x4f\xa5\x7f\x52\x0e\x51\x8c\x68\x05\x9b\xab\xd9\x83\x1f\x19\xcd\xe0\x5b"]],
["sha224_h0",["\xd8\x9e\x05\xc1\x07\xd5\x7c\x36\x17\xdd\x70\x30\x39\x59\x0e\xf7\x31\x0b\xc0\xff\x11\x15\x58\x68\xa7\x8f\xf9\x64\xa4\x4f\xfa\xbe"]],
["sha512_h0",["\x67\xe6\x09\x6a\x08\xc9\xbc\xf3\x85\xae\x67\xbb\x3b\xa7\xca\x84\x72\xf3\x6e\x3c\x2b\xf8\x94\xfe\x3a\xf5\x4f\xa5\xf1\x36\x1d\x5f\x7f\x52\x0e\x51\xd1\x82\xe6\xad\x8c\x68\x05\x9b\x1f\x6c\x3e\x2b\xab\xd9\x83\x1f\x6b\xbd\x41\xfb\x19\xcd\xe0\x5b\x79\x21\x7e\x13"]],
["ripe_md160",["\x00\x00\x00\x00\x99\x79\x82\x5a\xa1\xeb\xd9\x6e\xdc\xbc\x1b\x8f\x4e\xfd\x53\xa9\xe6\x8b\xa2\x50\x24\xd1\x4d\x5c\xf3\x3e\x70\x6d\xe9\x76\x6d\x7a\x00\x00\x00\x00"]],
["GOST_Sbox",["\x04\x0a\x09\x02\x0d\x08\x00\x0e\x06\x0b\x01\x0c\x07\x0f\x05\x03\x0e\x0b\x04\x0c\x06\x0d\x0f\x0a\x02\x03\x08\x01\x00\x07\x05\x09\x05\x08\x01\x0d\x0a\x03\x04\x02\x0e\x0f\x0c\x07\x06\x00\x09\x0b\x07\x0d\x0a\x01\x00\x08\x09\x0f\x0e\x04\x06\x0c\x0b\x02\x05\x03\x06\x0c\x07\x01\x05\x0f\x0d\x08\x04\x0a\x09\x0e\x00\x03\x0b\x02\x04\x0b\x0a\x00\x07\x02\x01\x0d\x03\x06\x08\x05\x09\x0c\x0f\x0e\x0d\x0b\x04\x01\x03\x0f\x05\x09\x00\x0a\x0e\x07\x06\x08\x02\x0c\x01\x0f\x0d\x00\x05\x07\x0a\x04\x09\x02\x03\x0e\x06\x0b\x08\x0c"]],
["MT19937 coefficient (Mersenne Twister)",["\x65\x89\x07\x6C","\x80\x56\x2C\x9D","\x00\x00\x6C\xEF","\xDF\xB0\x08\x99"]],
["RC5/RC6 magic",["\x63\x51\xe1\xb7","\x62\x51\xe1\xb7","\x6b\x2a\xed\x8a","\xb9\x79\x37\x9e","\x15\x7c\x4a\x7f"]]]

MASK32 = 0xffffffff
def murmur3_32_rotl(x, r)
  ((x << r) | (x >> (32 - r))) & MASK32
end


def murmur3_32_fmix(h)
  h &= MASK32
  h ^= h >> 16
  h = (h * 0x85ebca6b) & MASK32
  h ^= h >> 13
  h = (h * 0xc2b2ae35) & MASK32
  h ^ (h >> 16)
end

def murmur3_32__mmix(k1)
  k1 = (k1 * 0xcc9e2d51) & MASK32
  k1 = murmur3_32_rotl(k1, 15)
  (k1 * 0x1b873593) & MASK32
end

def murmur3_32_str_hash(str, seed=0)
  h1 = seed
  numbers = str.unpack('V*C*')
  tailn = str.bytesize % 4
  tail = numbers.slice!(numbers.size - tailn, tailn)
  for k1 in numbers
    h1 ^= murmur3_32__mmix(k1)
    h1 = murmur3_32_rotl(h1, 13)
    h1 = (h1*5 + 0xe6546b64) & MASK32
  end
  
  
  unless tail.empty?
    k1 = 0
    tail.reverse_each do |c1|
      k1 = (k1 << 8) | c1
    end
    h1 ^= murmur3_32__mmix(k1)
  end

  h1 ^= str.bytesize
  murmur3_32_fmix(h1)
end

def poliLinkAddr(address)
    "[0x#{address.to_s(16)}](./disassemble/#{address.to_s(16)})"
end

def AddTagFunction(funcaddr, tagname)
    if @tbFuncName[funcaddr] == nil
        @tbFuncName[funcaddr] = tagname+"sub_#{funcaddr.to_s(16).upcase}"
    else
        @tbFuncName[funcaddr] = tagname+@tbFuncName[funcaddr] if not @tbFuncName[funcaddr].include?(tagname)
    end
end

def is_linked_block(di, start_address)
    result = false
    @loopcount += 1
    return false if @loopcount > 500
    return result if not defined?(di.block)
    return result if di.block.to_normal == nil
    di.block.to_normal.each{|tdi_addr|
        tdi = $gdasm.di_at(tdi_addr)
        next if not defined?(tdi.block)
        return true if tdi.block.address == start_address
        next if @blocks_done.include? tdi.address
        @blocks_done << tdi.block.address
        return true if is_linked_block(tdi, start_address)
    }
    result
end

def is_looping(di)
    @blocks_done = []
    @loopcount = 0
    result = false

    return result if not defined?(di.block)
    return result if di.block.to_normal == nil
    start_address = di.block.address

    di.block.to_normal.each{|tdi_addr|
        tdi = $gdasm.di_at(tdi_addr)
        next if not defined?(tdi.block)
        return true if tdi.block.address == start_address
        next if @blocks_done.include? di.address
        @blocks_done << tdi.block.address
        return true if is_linked_block(tdi, start_address)
    }
    result
end


def getArg(addrori,arg)
    di = $gdasm.di_at(addrori)
    return nil if not defined?(di.opcode)
    
    carg = 0
    esp = 4*arg
    if di.opcode.name == "call"
        i = di.block.list.length
        while i > 0
            if di.block.list[i-1].address == addrori
                i -= 1
                while i > 0
                    if di.block.list[i-1].opcode.name == 'push'
                        if carg == arg
                            return $gdasm.normalize(di.block.list[i-1].instruction.args.first)
                        end
                        carg += 1
                        esp -= 4
                    end
                    if (di.block.list[i-1].opcode.name == 'mov') and ((di.block.list[i-1].instruction.args.first.to_s == "dword ptr [esp+0#{arg.to_s(16)}h]") or (((di.block.list[i-1].instruction.args.first.to_s == "dword ptr [esp]") and (esp == 0))))
                        return $gdasm.normalize(di.block.list[i-1].instruction.args.last)
                    end
                    
                    if di.block.list[i-1].opcode.name == 'call'
                        return nil
                    end
                    i -= 1
                end
            end
            i -= 1
        end
    end
    if di.opcode.name == "mov"
        creg = di.instruction.args.first
        i = 0
        carg = 0
        while i < di.block.list.length
            if di.block.list[i].address == addrori
                while i < di.block.list.length
                    if di.block.list[i].opcode.name == 'call' and di.block.list[i].instruction.args.first == creg
                        i -= 1
                        while i >= 0
                            if di.block.list[i].opcode.name == 'push'
                                if carg == arg
                                    return $gdasm.normalize(di.block.list[i].instruction.args.first)
                                end
                                carg += 1
                                esp -= 4
                            end
                            if di.block.list[i].opcode.name == 'mov' and ((di.block.list[i].instruction.args.first.to_s == "[esp+0#{(arg).to_s(16)}h]" or ((di.block.list[i].instruction.args.first.to_s == "dword ptr [esp]") and esp == 0)))
                                return di.block.list[i].instruction.args.last
                            end
                            
                            if di.block.list[i].opcode.name == 'call'
                                return nil
                            end
                            i -= 1
                        end
                        return nil
                    end
                    i += 1
                end
            end
            i += 1
        end
    end
end

def checkCall(strFunc, xrefCall)
    basefunc = find_start_of_function(xrefCall)
    if basefunc != nil
        log("")
        log("Top of function : #{poliLinkAddr(basefunc)} ; Top of block : #{poliLinkAddr($gdasm.di_at(xrefCall).block.list[0].address)}")
        log("")
    end
        if strFunc == "IsDebuggerPresent"
        log("  *   #{poliLinkAddr(xrefCall)} -> IsDebuggerPresent()")
        return
    end
    if strFunc == "OpenSCManagerW"
        arg1 = getArg(xrefCall,0)
        if $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_wstrz(arg1).gsub(/[\x00]/n, '')
        else
            arg1 = ''
        end
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_wstrz(arg2)
            arg2 = $gdasm.decode_wstrz(arg2).gsub(/[\x00]/n, '')
        else
            arg2 = ''
        end
        if arg1 != '' or arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> OpenSCManagerW('#{arg1}','#{arg2}')")
        end
        return
    end
    if strFunc == "OpenSCManagerA"
        arg1 = getArg(xrefCall,0)
        if $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_strz(arg1)
        else
            arg1 = ''
        end
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_wstrz(arg2)
            arg2 = $gdasm.decode_strz(arg2)
        else
            arg2 = ''
        end
        if arg1 != '' or arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> OpenSCManagerA('#{arg1}','#{arg2}')")
        end
        return
    end
    if strFunc == "CreateProcessW"
        arg1 = getArg(xrefCall,0)
        if $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_wstrz(arg1).gsub(/[\x00]/n, '')
        else
            arg1 = ''
        end
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_wstrz(arg2)
            arg2 = $gdasm.decode_wstrz(arg2).gsub(/[\x00]/n, '')
        else
            arg2 = ''
        end
        AddTagFunction(basefunc, "Proc_") if basefunc != nil
        if arg1 != '' or arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> CreateProcessW('#{arg1}','#{arg2}')")
        end
        return
    end
    if strFunc == "CreateServiceA"
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_strz(arg2)
            arg2 = $gdasm.decode_strz(arg2)
        else
            arg2 = ''
        end
        arg3 = getArg(xrefCall,2)
        if $gdasm.decode_strz(arg3)
            arg3 = $gdasm.decode_strz(arg3)
        else
            arg3 = ''
        end
        AddTagFunction(basefunc, "Serv_") if basefunc != nil
        if arg2 != '' or arg3 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> CreateServiceA('#{arg2}','#{arg3}')")
        end
        return
    end
    if strFunc == "WinExec"
        arg1 = getArg(xrefCall,0)
        if $gdasm.decode_strz(arg1)
            arg1 = $gdasm.decode_strz(arg1)
        else
            arg1 = ''
        end
        AddTagFunction(basefunc, "Proc_") if basefunc != nil
        if arg1 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> WinExec('#{arg1}')")
        end
        return
    end
    if strFunc == "CreateProcessA"
        arg1 = getArg(xrefCall,0)
        if $gdasm.decode_strz(arg1)
            arg1 = $gdasm.decode_strz(arg1)
        else
            arg1 = ''
        end
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_strz(arg2)
            arg2 = $gdasm.decode_strz(arg2)
        else
            arg2 = ''
        end
        AddTagFunction(basefunc, "Proc_") if basefunc != nil
        if arg1 != '' or arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> CreateProcessA('#{arg1}','#{arg2}')")
        end
        return
    end
    if strFunc == "VirtualProtect"
        arg1 = getArg(xrefCall,0)
        arg2 = getArg(xrefCall,1)
        arg3 = getArg(xrefCall,2)
        if $gdasm.decode_dword(arg1)
            arg1 = "0x#{$gdasm.decode_dword(arg1).to_s(16)}"
        else
            arg1 = ''
        end
        if $gdasm.decode_dword(arg2)
            arg2 = "0x#{$gdasm.decode_dword(arg2).to_s(16)}"
        else
            arg2 = ''
        end
        if arg3
            case arg3
            when 0x10
                arg3 = 'PAGE_EXECUTE'
            when 0x20
                arg3 = 'PAGE_EXECUTE_READ'
            when 0x40
                arg3 = 'PAGE_EXECUTE_READWRITE'
            when 0x80
                arg3 = 'PAGE_EXECUTE_WRITECOPY'
            when 0x01
                arg3 = 'PAGE_NOACCESS'
            when 0x02
                arg3 = 'PAGE_READONLY'
            when 0x04
                arg3 = 'PAGE_READWRITE'
            when 0x08
                arg3 = 'PAGE_WRITECOPY'
            else
                arg3 = ''
            end
        else
            arg3 = ''
        end
        if arg3 != ''
            @tbComments[xrefCall] = "VirtualProtect(#{arg1},#{arg2},#{arg3})" if arg1.to_s != '' or arg2.to_s != '' or arg3.to_s != ''
        end
        if arg1 != '' or arg2 != '' or  arg3 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> VirtualProtect(#{arg1},#{arg2},#{arg3})")
        end
        return
    end
    if strFunc == "MoveFileA"
        arg1 = getArg(xrefCall,0)
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_strz(arg1)
            arg1 = $gdasm.decode_strz(arg1)
        else
            arg1 = ''
        end
        if $gdasm.decode_strz(arg2)
            arg2 = $gdasm.decode_strz(arg2)
        else
            arg2 = ''
        end
        AddTagFunction(basefunc, "File_") if basefunc != nil
        if arg1 != '' or arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> MoveFileA('#{arg1}','#{arg2}')")
        end
        return
    end
    if strFunc == "MoveFileW"
        arg1 = getArg(xrefCall,0)
        if $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_wstrz(arg1).gsub(/[\x00]/n, '')
        else
            arg1 = ''
        end
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_wstrz(arg2)
            arg2 = $gdasm.decode_wstrz(arg2).gsub(/[\x00]/n, '')
        else
            arg2 = ''
        end
        AddTagFunction(basefunc, "File_") if basefunc != nil
        if arg1 != '' or arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> MoveFileW('#{arg1}','#{arg2}')")
        end
        return
    end
    if strFunc == "CopyFileA"
        arg1 = getArg(xrefCall,0)
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_strz(arg1)
            arg1 = $gdasm.decode_strz(arg1)
        else
            arg1 = ''
        end
        if $gdasm.decode_strz(arg2)
            arg2 = $gdasm.decode_strz(arg2)
        else
            arg2 = ''
        end
        AddTagFunction(basefunc, "File_") if basefunc != nil
        if arg1 != '' or arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> CopyFileA('#{arg1}','#{arg2}')")
        end
        return
    end
    if strFunc == "CopyFileW"
        arg1 = getArg(xrefCall,0)
        if $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_wstrz(arg1).gsub(/[\x00]/n, '')
        else
            arg1 = ''
        end
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_wstrz(arg2)
            arg2 = $gdasm.decode_wstrz(arg2).gsub(/[\x00]/n, '')
        else
            arg2 = ''
        end
        AddTagFunction(basefunc, "File_") if basefunc != nil
        if arg1 != '' or arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> CopyFileW('#{arg1}','#{arg2}')")
        end
        return
    end
    if strFunc == "DeleteFileA"
        arg1 = getArg(xrefCall,0)
        if $gdasm.decode_strz(arg1)
            arg1 = $gdasm.decode_strz(arg1)
        else
            arg1 = ''
        end
        AddTagFunction(basefunc, "File_") if basefunc != nil
        if arg1 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> DeleteFileA('#{arg1}')")
        end
        return
    end
    if strFunc == "DeleteFileW"
        # pp addr.to_s(16)
        arg1 = getArg(xrefCall,0)
        if $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_wstrz(arg1).gsub(/[\x00]/n, '')
        else
            arg1 = ''
        end
        AddTagFunction(basefunc, "File_") if basefunc != nil
        if arg1 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> DeleteFileW('#{arg1}')")
        end
        return
    end
    if strFunc == "RegSetValueExW"
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_wstrz(arg2)
            arg2 = $gdasm.decode_wstrz(arg2).gsub(/[\x00]/n, '')
        else
            arg2 = ''
        end
        AddTagFunction(basefunc, "Reg_") if basefunc != nil
        if arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> RegSetValueExW('#{arg2}')")
        end
        return
    end
    if strFunc == "RegSetValueExA"
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_strz(arg2)
            arg2 = $gdasm.decode_strz(arg2)
        else
            arg2 = ''
        end
        AddTagFunction(basefunc, "Reg_") if basefunc != nil
        if arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> RegSetValueExA('#{arg2}')")
        end
        return
    end
    if strFunc == "RegSetValueA"
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_strz(arg2)
            arg2 = $gdasm.decode_strz(arg2)
        else
            arg2 = ''
        end
        AddTagFunction(basefunc, "Reg_") if basefunc != nil
        if arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> RegSetValueA('#{arg2}')")
        end
        return
    end
    if strFunc == "CreateDirectoryW"
        arg1 = getArg(xrefCall,0)
        if $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_wstrz(arg1).gsub(/[\x00]/n, '')
        else
            arg1 = ''
        end
        AddTagFunction(basefunc, "File_") if basefunc != nil
        if arg1 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> CreateDirectoryW('#{arg1}')")
        end
        return
    end
    if strFunc == "RegOpenKeyW"
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_wstrz(arg2)
            arg2 = $gdasm.decode_wstrz(arg2).gsub(/[\x00]/n, '')
        else
            arg2 = ''
        end
        AddTagFunction(basefunc, "Reg_") if basefunc != nil
        if arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> RegOpenKeyW('#{arg2}')")
        end
        return
    end
    if strFunc == "RegOpenKeyA"
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_strz(arg2)
            arg2 = $gdasm.decode_strz(arg2)
        else
            arg2 = ''
        end
        AddTagFunction(basefunc, "Reg_") if basefunc != nil
        if arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> RegOpenKeyA('#{arg2}')")
        end
        return
    end
    if strFunc == "RegOpenKeyExA"
        arg2 = getArg(xrefCall,1)
        AddTagFunction(basefunc, "Reg_") if basefunc != nil
        if arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> RegOpenKeyExA('#{$gdasm.decode_strz(arg2)}')")
        end
        return
    end
    if strFunc == "RegCreateKeyW"
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_wstrz(arg2)
            arg2 = $gdasm.decode_wstrz(arg2).gsub(/[\x00]/n, '')
        else
            arg2 = ''
        end
        AddTagFunction(basefunc, "Reg_") if basefunc != nil
        if arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> RegCreateKeyW('#{$gdasm.decode_strz(arg2)}')")
        end
        return
    end
    if strFunc == "RegCreateKeyA"
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_strz(arg2)
            arg2 = $gdasm.decode_strz(arg2)
        else
            arg2 = ''
        end
        AddTagFunction(basefunc, "Reg_") if basefunc != nil
        if arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> RegCreateKeyA('#{$gdasm.decode_strz(arg2)}')")
        end
        return
    end
    if strFunc == "RegOpenKeyExW"
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_wstrz(arg2)
            arg2 = $gdasm.decode_wstrz(arg2).gsub(/[\x00]/n, '')
        else
            arg2 = ''
        end
        AddTagFunction(basefunc, "Reg_") if basefunc != nil
        if arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> RegOpenKeyExW('#{arg2}')")
        end
        return
    end
    if strFunc == "CreateDirectoryA"
        arg1 = getArg(xrefCall,0)
        AddTagFunction(basefunc, "File_") if basefunc != nil
        if arg1 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> CreateDirectoryA('#{$gdasm.decode_strz(arg1)}')")
        end
        return
    end
    if strFunc == "InternetCheckConnectionA"
        arg1 = getArg(xrefCall,0)
        AddTagFunction(basefunc, "Net_") if basefunc != nil
        if arg1 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> InternetCheckConnectionA('#{$gdasm.decode_strz(arg1)}')")
        end
        return
    end
    if strFunc == "InternetCheckConnectionW"
        arg1 = getArg(xrefCall,0)
        if $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_wstrz(arg1).gsub(/[\x00]/n, '')
        else
            arg1 = ''
        end
        AddTagFunction(basefunc, "Net_") if basefunc != nil
        if arg1 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> InternetCheckConnectionW('#{arg1}')")
        end
        return
    end
    if strFunc == "InternetOpenA"
        arg1 = getArg(xrefCall,0)
        if $gdasm.decode_strz(arg1)
            arg1 = $gdasm.decode_strz(arg1)
        else
            arg1 = ''
        end
        AddTagFunction(basefunc, "Net_") if basefunc != nil
        if arg1 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> InternetOpenA('#{arg1}')")
        end
        return
    end
    if strFunc == "OpenServiceA"
        arg1 = getArg(xrefCall,1)
        if $gdasm.decode_strz(arg1)
            arg1 = $gdasm.decode_strz(arg1)
        else
            arg1 = ''
        end
        AddTagFunction(basefunc, "Serv_") if basefunc != nil
        if arg1 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> OpenServiceA('#{arg1}')")
        end
        return
    end
    if strFunc == "OpenServiceW"
        arg1 = getArg(xrefCall,1)
        if $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_wstrz(arg1).gsub(/[\x00]/n, '')
        else
            arg1 = ''
        end
        AddTagFunction(basefunc, "Serv_") if basefunc != nil
        if arg1 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> OpenServiceW('#{arg1}')")
        end
        return
    end
    if strFunc == "InternetOpenW"
        arg1 = getArg(xrefCall,0)
        if $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_wstrz(arg1).gsub(/[\x00]/n, '')
        else
            arg1 = ''
        end
        AddTagFunction(basefunc, "Net_") if basefunc != nil
        if arg1 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> InternetOpenW('#{arg1}')")
        end
        return
    end
    if strFunc == "InternetOpenUrlW"
        arg1 = getArg(xrefCall,1)
        arg2 = getArg(xrefCall,2)
        if $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_wstrz(arg1).gsub(/[\x00]/n, '')
        else
            arg1 = ''
        end
        if $gdasm.decode_wstrz(arg2)
            arg2 = $gdasm.decode_wstrz(arg2).gsub(/[\x00]/n, '')
        else
            arg2 = ''
        end
        AddTagFunction(basefunc, "Net_") if basefunc != nil
        if arg1 != '' or arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> InternetOpenUrlW('#{arg1}','#{arg2}')")
        end
        return
    end
    if strFunc == "InternetConnectW"
        arg1 = getArg(xrefCall,1)
        if $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_wstrz(arg1).gsub(/[\x00]/n, '')
        else
            arg1 = ''
        end
        AddTagFunction(basefunc, "Net_") if basefunc != nil
        if arg1 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> InternetOpenW('#{arg1}')")
        end
        return
    end
    if strFunc == "HttpAddRequestHeadersW"
        arg1 = getArg(xrefCall,1)
        if $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_wstrz(arg1).gsub(/[\x00]/n, '')
        else
            arg1 = ''
        end
        AddTagFunction(basefunc, "Net_") if basefunc != nil
        if arg1 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> HttpAddRequestHeadersW('#{arg1}')")
        end
        return
    end
    if strFunc == "CoCreateInstance"
        arg1 = getArg(xrefCall,0)
        if $gdasm.decode_dword(arg1)
            arg1 = "{%08X-%04X-%04X-%02X%02X-%02X%02X%02X%02X%02X%02X}" % [$gdasm.decode_dword(arg1), ($gdasm.decode_dword(arg1+4) & 0xffff), ($gdasm.decode_dword(arg1+6) & 0xffff), $gdasm.decode_byte(arg1+8), $gdasm.decode_byte(arg1+9), $gdasm.decode_byte(arg1+10), $gdasm.decode_byte(arg1+11), $gdasm.decode_byte(arg1+12), $gdasm.decode_byte(arg1+13), $gdasm.decode_byte(arg1+14), $gdasm.decode_byte(arg1+15), $gdasm.decode_byte(arg1+16)]
            @tbComments[xrefCall] = "Instance : #{arg1}" if arg1.to_s != ''
            if arg1.casecmp("{0002df01-0000-0000-c000-000000000046}") == 0
                arg1 += " (CLSID_InternetExplorer)"
                @tbComments[xrefCall] += " (CLSID_InternetExplorer)"
                AddTagFunction(basefunc, "Net_") if basefunc != nil
            end 
            if arg1.casecmp("{0002DF05-0000-0000-C000-000000000046}") == 0
                arg1 += " (IID_IWebBrowserApp)"
                @tbComments[xrefCall] += " (IID_IWebBrowserApp)"
                AddTagFunction(basefunc, "Net_") if basefunc != nil
            end
            if arg1.casecmp("{00021401-0000-0000-C000-000000000046}") == 0
                arg1 += " (CLSID_LNK)"
                @tbComments[xrefCall] += " (CLSID_LNK)"
            end
        else
            arg1 = ''
        end
        if arg1 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> CoCreateInstance('#{arg1}')")
        end
        return
    end
    if strFunc == "send"
        arg1 = getArg(xrefCall,1)
        arg2 = getArg(xrefCall,2)
        if $gdasm.decode_strz(arg1)
            arg1 = $gdasm.decode_strz(arg1)
        elsif $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_wstrz(arg1).gsub(/[\x00]/n, '')
        else
            arg1 = ''
        end
        if $gdasm.decode_dword(arg2)
            arg2 = $gdasm.decode_dword(arg2)
        else
            arg2 = ''
        end
        AddTagFunction(basefunc, "Net_") if basefunc != nil
        if arg1 != '' or arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> send('#{arg1}',#{arg2})")
        end
        return
    end
    if strFunc == "gethostbyname"
        arg1 = getArg(xrefCall,0)
        if $gdasm.decode_strz(arg1)
            arg1 = $gdasm.decode_strz(arg1)
        else
            arg1 = ''
        end
        AddTagFunction(basefunc, "Net_") if basefunc != nil
        if arg1 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> gethostbyname('#{arg1}')")
        end
        return
    end
    if strFunc == "inet_addr"
        arg1 = getArg(xrefCall,0)
        if $gdasm.decode_strz(arg1)
            arg1 = $gdasm.decode_strz(arg1)
        else
            arg1 = ''
        end
        AddTagFunction(basefunc, "Net_") if basefunc != nil
        if arg1 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> inet_addr('#{arg1}')")
        end
        return
    end
    if strFunc == "system"
        arg1 = getArg(xrefCall,0)
        if $gdasm.decode_strz(arg1)
            arg1 = $gdasm.decode_strz(arg1)
        else
            arg1 = ''
        end
        AddTagFunction(basefunc, "Proc_") if basefunc != nil
        if arg1 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> system('#{arg1}')")
        end
        return
    end
    if strFunc == "SHGetValueA"
        arg1 = getArg(xrefCall,1)
        arg2 = getArg(xrefCall,2)
        if $gdasm.decode_strz(arg1)
            arg1 = $gdasm.decode_strz(arg1)
        else
            arg1 = ''
        end
        if $gdasm.decode_strz(arg2)
            arg2 = $gdasm.decode_strz(arg2)
        else
            arg2 = ''
        end
        AddTagFunction(basefunc, "Reg_") if basefunc != nil
        if arg1 != '' or arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> SHGetValueA('#{arg1}','#{arg2}')")
        end
        return
    end
    if strFunc == "SHGetValueW"
        arg1 = getArg(xrefCall,1)
        arg2 = getArg(xrefCall,2)
        if $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_wstrz(arg1).gsub(/[\x00]/n, '')
        else
            arg1 = ''
        end
        if $gdasm.decode_wstrz(arg2)
            arg2 = $gdasm.decode_wstrz(arg2).gsub(/[\x00]/n, '')
        else
            arg2 = ''
        end
        AddTagFunction(basefunc, "Reg_") if basefunc != nil
        if arg1 != '' or arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> SHGetValueW('#{arg1}','#{arg2}')")
        end
        return
    end
    if strFunc == "IoCreateDevice"
        arg1 = getArg(xrefCall,2)
        if $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_wstrz(arg1).gsub(/[\x00]/n, '')
        else
            arg1 = ''
        end
        if arg1 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> IoCreateDevice('#{arg1}')")
        end
        return
    end
    if strFunc == "RtlInitUnicodeString"
        arg1 = getArg(xrefCall,0)
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_wstrz(arg1).gsub(/[\x00]/n, '')
        else
            arg1 = ''
        end
        if $gdasm.decode_wstrz(arg2)
            arg2 = $gdasm.decode_wstrz(arg2).gsub(/[\x00]/n, '')
        else
            arg2 = ''
        end
        if arg1 != '' or arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> RtlInitUnicodeString('#{arg1}','#{arg2}')")
        end
        return
    end
    if strFunc == "RtlAppendUnicodeToString"
        arg1 = getArg(xrefCall,0)
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_wstrz(arg1).gsub(/[\x00]/n, '')
        else
            arg1 = ''
        end
        if $gdasm.decode_wstrz(arg2)
            arg2 = $gdasm.decode_wstrz(arg2).gsub(/[\x00]/n, '')
        else
            arg2 = ''
        end
        if arg1 != '' or arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> RtlAppendUnicodeToString('#{arg1}','#{arg2}')")
        end
        return
    end
    if strFunc == "RtlWriteRegistryValue"
        arg1 = getArg(xrefCall,1)
        arg2 = getArg(xrefCall,2)
        if $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_wstrz(arg1).gsub(/[\x00]/n, '')
        else
            arg1 = ''
        end
        if $gdasm.decode_wstrz(arg2)
            arg2 = $gdasm.decode_wstrz(arg2).gsub(/[\x00]/n, '')
        else
            arg2 = ''
        end
        AddTagFunction(basefunc, "Reg_") if basefunc != nil
        if arg1 != '' or arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> RtlWriteRegistryValue('#{arg1}','#{arg2}')")
        end
        return
    end
    if strFunc == "IoCreateSymbolicLink"
        arg1 = getArg(xrefCall,0)
        arg2 = getArg(xrefCall,1)
        if $gdasm.decode_wstrz(arg1)
            arg1 = $gdasm.decode_wstrz(arg1).gsub(/[\x00]/n, '')
        else
            arg1 = ''
        end
        if $gdasm.decode_wstrz(arg2)
            arg2 = $gdasm.decode_wstrz(arg2).gsub(/[\x00]/n, '')
        else
            arg2 = ''
        end
        if arg1 != '' or arg2 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> IoCreateSymbolicLink('#{arg1}','#{arg2}')")
        end
        return
    end
    if strFunc == "connect"
        arg1 = getArg(xrefCall,1)
        if $gdasm.decode_dword(arg1)
            arg1 = ":%d" % ( ($gdasm.decode_dword(arg1) & 0xffff) )
        else
            arg1 = ''
        end
        AddTagFunction(basefunc, "Net_") if basefunc != nil
        if arg1 != ''
            log("  *   #{poliLinkAddr(xrefCall)} -> connect(#{arg1})")
        end
        return
    end
end

# is_modrm : ensure that arg is a modrm : [esp+4], etc.
def is_modrm(arg)
    return (arg and arg.kind_of? Ia32::ModRM)
end

def find_start_of_function(address)
    blocks = []
    di = $gdasm.di_at(address)
    return nil if not defined?(di.instruction)
    return nil if not defined?(di.block)
    while (defined?(di.block.from_normal.length) and di.block.from_normal.length > 0) or (defined?(di.block.from_subfuncret.length) and di.block.from_subfuncret.length > 0)
        if defined?(di.block.from_normal.length)
            max = di.block.from_normal.length
            i = 0
            while blocks.include? di.block.from_normal[i] and i < di.block.from_normal.length
                i+=1
            end
        end
        
        if di.block.list[0].block.from_normal == nil and di.block.list[0].block.from_subfuncret != nil and di.block.list[0].block.from_subfuncret.length == 1
            blocks << di.address
            di = $gdasm.di_at(di.block.list[0].block.from_subfuncret[0])
        elsif
            blocks << di.address
            di.block.list[0].block.from_normal != nil
            di = $gdasm.di_at(di.block.from_normal[i])
        end
        return nil if not defined?(di.block)
        return di.block.list[0].address if $gdasm.function[di.block.list[0].address]
    end
    return di.block.list[0].address if $gdasm.function[di.block.list[0].address]
    return nil
end

def getBranch(list, value)
    currlist = []
    return false if defined?(list.length) and list.length == 0
    if not defined?(list.length)
        return value if list == value
        return false
    end
    i = 0
    while i < list.length
        if list[i] == value
            currlist << list[i]
            i += 2
            next
        end
        if getBranch(list[i+1], value) != false
            currlist << list[i]
        end
        i += 2
    end
    return false if currlist == []
    return currlist
end

def getFromFunc(addressFunc)
    @treefuncs.each{|funcaddr,to_normal,from_normal|
        return from_normal if funcaddr == addressFunc
    }
end

def getToFunc(addressFunc)
    a = @treefuncs.each{|funcaddr,to_normal,from_normal|
        return to_normal if funcaddr == addressFunc
    }
end

def is_linked_func(currFunc, start_address, stop_address)
    result = false
    return true if currFunc == stop_address
    @tree_done << currFunc
    getToFunc(currFunc).each{|tdi_addr|
        next if defined?(tdi_addr.length)
        next if @tree_done.include? tdi_addr
        @tree_done << tdi_addr
        result = is_linked_func(tdi_addr, start_address, stop_address)
        return true if result == true
    }
    result
end

def isFuncTreeLink(fromaddr, toaddr)
    result = false
    @tree_done = []
    result = is_linked_func(fromaddr, fromaddr, toaddr)
    result
end

def countSubCallTree(fromaddr, toaddr)
    return 0 if fromaddr == toaddr
    count = 0
    getToFunc(fromaddr).each{|tdi_addr|
        count += 1 if isFuncTreeLink(tdi_addr, toaddr)
    }
    count
end

def calculateSizeSubCallTree(fromaddr, toaddr,indent,cnt)
    return 0 if fromaddr == toaddr
    i = 0
    total = 1
    if indent.length > 5
        return total
    end
    getToFunc(fromaddr).each{|tdi_addr|
        if isFuncTreeLink(tdi_addr, toaddr)
            tindent = []
            i += 1
            indent.each{|id, iscontinue|
                tindent << [id, iscontinue]
            }
            if i == cnt
                tindent << [indent.length,false]
            else
                tindent << [indent.length,true]
            end 
            total += calculateSizeSubCallTree(tdi_addr, toaddr, tindent,countSubCallTree(tdi_addr, toaddr))
        end
    }
    total
end

def printSubCallTree(fromaddr, toaddr,indent,cnt)
    return if fromaddr == toaddr
    i = 0
    space1 = ""
    indent.each{|id, iscontinue|
        space1 += "       "
        if iscontinue
            space1 += "|"
        else
            space1 += " "
        end
    }
    if indent.length > 9
        log(space1+"       +- [...]")
        @glinestree -= 1
        if @glinestree == 0
            log("    [...]")
        end
        return
    end
    getToFunc(fromaddr).each{|tdi_addr|
        if isFuncTreeLink(tdi_addr, toaddr)
            tindent = []
            i += 1
            indent.each{|id, iscontinue|
                space1 = ""
                indent.each{|id, iscontinue|
                    space1 += "       "
                    if iscontinue
                        space1 += "|"
                    else
                        space1 += " "
                    end
                }
                tindent << [id, iscontinue]
            }
            @glinestree -= 1
            if @glinestree == 0
                log("    [...]")
            end
            return if @glinestree < 1
            log(space1+"       +- #{poliLinkAddr(tdi_addr)}")
            if i == cnt
                tindent << [indent.length,false]
            else
                tindent << [indent.length,true]
            end 
            printSubCallTree(tdi_addr, toaddr, tindent,countSubCallTree(tdi_addr, toaddr))
        end
    }
end

def printCallTree(fromaddr, toaddr)
    @currenttree_done = []
    i = 0
    @glinestree = 9999
    log("")
    log("Call tree from entry point to function :")
    log("")
    log("\n")
    if calculateSizeSubCallTree(fromaddr, toaddr, [[0,false]],countSubCallTree(fromaddr, toaddr)) > 20
        @glinestree = 40
    end
    log("    - #{poliLinkAddr(fromaddr)} (entrypoint/EAT/TLS)")
    getToFunc(fromaddr).each{|tdi_addr|
        if isFuncTreeLink(tdi_addr, toaddr)
            i += 1
            @glinestree -= 1
            if @glinestree == 0
                log("    [...]")
            end
            log("\n") if @glinestree < 1
            return if @glinestree < 1
            log("       +- #{poliLinkAddr(tdi_addr)}")
            if i == countSubCallTree(fromaddr, toaddr)
                printSubCallTree(tdi_addr, toaddr, [[0,false]],countSubCallTree(tdi_addr, toaddr))
            else
                printSubCallTree(tdi_addr, toaddr, [[0,true]],countSubCallTree(tdi_addr, toaddr))
            end
        end
    }
    log("\n")
end

def repareIatLinks()
    $gdasm.decoded.each{|addr, di|
        if di.opcode.name == 'mov' and defined?(di.instruction.args.last.symbolic.target)
            label = $gdasm.get_label_at(di.instruction.args.last.symbolic.target.bind.reduce)
            if label =~ /^iat_/
                if $gdasm.xrefs[di.instruction.args.last.symbolic.target.bind.reduce] == nil
                    $gdasm.xrefs[di.instruction.args.last.symbolic.target.bind.reduce] = [di.instruction.args.last.symbolic.target.bind.reduce, di]
                elsif not $gdasm.xrefs[di.instruction.args.last.symbolic.target.bind.reduce].include? di
                    $gdasm.xrefs[di.instruction.args.last.symbolic.target.bind.reduce] |= [di]
                end
            end
        end
    }
end

def log(stringtolog)
    if defined?($SIMPLE)
        print(stringtolog+"\n")
    else
        @file.write(stringtolog+"\n")
    end
end


# the filename of our target binary
target = ARGV.shift || 'bla.exe'

md5sum = Digest::MD5.file(target).hexdigest
sha1sum = Digest::SHA1.file(target).hexdigest
sha256sum = Digest::SHA256.file(target).hexdigest
filesize = File.stat(target).size 

@file = File.open("#{target}.txt", "w") if not defined?($SIMPLE)

title = "Static analyze of binary"
title += "\n"+("="*title.length)+"\n\n"
log(title)

# the entrypoints to obfuscated functions
entrypoints = ARGV.map { |ep| Integer(ep) rescue ep }

# load binary
decodedfile = AutoExe.decode_file(target)
entrypoints =  decodedfile.get_default_entrypoints if entrypoints.empty?
dasm = decodedfile.disassembler
$gdasm = dasm
# disassemble obfuscated code

puts "  [*] Fast disassemble of binary..." if defined?($VERBOSEOPT)
dasm.disassemble_fast_deep(*entrypoints)

puts "  [*] Crawlling uncovered code..." if defined?($VERBOSEOPT)
# $DEBUG = 1
codePatterns = ["\x8b\xff", "\x55\x8b\xec", "\x55\x89\xe5", "\xff\x25", "\xff\x15", /\x68....\xe8/n,"\x48\x83\xec", "\x48\x89\x5c\x24"]

@treefuncs = []
@listoffunct = []

dasm.sections.each{|secAddr, secDatas|
    next if dasm.decoded.first == nil
    if (secAddr <= dasm.decoded.first[0]) and ((secAddr+secDatas.data.length) > dasm.decoded.first[0])
        codePatterns.each{|pattern|
            i = 0
            while i < secDatas.data.length
                bi = i
                pattAddr = secDatas.data[i..-1].index(pattern)
                if pattAddr != nil
                    if dasm.di_at(secAddr+i+pattAddr) == nil
                        if defined?($FASTDISAS)
                            puts "    [+] Pattern found at 0x#{(secAddr+i+pattAddr).to_s(16)} fast disassembling in process..." if defined?($VERBOSEOPT)
                            dasm.disassemble_fast_deep(secAddr+i+pattAddr)
                        else
                            puts "    [+] Pattern found at 0x#{(secAddr+i+pattAddr).to_s(16)} fast disassembling in process..." if defined?($VERBOSEOPT)
                            dasm.disassemble_fast_deep(secAddr+i+pattAddr)
                        end
                    end
                    if dasm.function[secAddr+i+pattAddr] == nil
                        if dasm.di_at(secAddr+i+pattAddr).block.from_subfuncret == nil and dasm.di_at(secAddr+i+pattAddr).block.from_normal == nil
                            dasm.function[secAddr+i+pattAddr] =  (dasm.function[:default] || dasm.DecodedFunction.new).dup
                            dasm.function[secAddr+i+pattAddr].finalized = true
                        end
                        dasm.disassemble_fast_checkfunc(secAddr+i+pattAddr)
                    end
                    i += pattAddr+1
                end
                i = secDatas.data.length if bi == i
            end
        }
    end
}

dasm.function.each{|addr, symb|
    if addr.to_s =~ /^[0-9]+$/
        toaddr = []
        fromaddr = []
        xreftree = dasm.get_xrefs_x(dasm.di_at(addr))
        xreftree.each{|xref_addr|
                fromaddr << xref_addr if xref_addr.to_s =~ /^[0-9]+$/
        }
        dasm.each_function_block(addr).each{|bloc|
            dasm.di_at(bloc[0]).block.list.each{|di|
                toaddr << dasm.normalize(di.instruction.args.first) if di.opcode.name == 'call' and dasm.normalize(di.instruction.args.first).to_s =~ /^[0-9]+$/
            }
        }
        toaddr = toaddr.sort.uniq
        fromaddr = fromaddr.sort.uniq
        @treefuncs << [addr, toaddr, fromaddr]
    end
}
entrypoints.each{|ep|
    if $gdasm.function[dasm.normalize(ep)] == nil
        toaddr = []
        fromaddr = []
        xreftree = dasm.get_xrefs_x(dasm.di_at(dasm.normalize(ep)))
        xreftree.each{|xref_addr|
                fromaddr << xref_addr if xref_addr.to_s =~ /^[0-9]+$/
        }
        dasm.each_function_block(dasm.normalize(ep)).each{|bloc|
            dasm.di_at(bloc[0]).block.list.each{|di|
                toaddr << dasm.normalize(di.instruction.args.first) if di.opcode.name == 'call' and dasm.normalize(di.instruction.args.first).to_s =~ /^[0-9]+$/
            }
        }
        toaddr = toaddr.sort.uniq
        fromaddr = fromaddr.sort.uniq
        @treefuncs << [dasm.normalize(ep), toaddr, fromaddr]
    end
}

@compiled_date = DateTime.strptime(decodedfile.header.time.to_s,'%s').to_s.gsub('T', ' ').gsub(/\+.*/, '')
log("Executable compiled the #{DateTime.strptime(decodedfile.header.time.to_s,'%s')}\n")


@allintructionssize = 0
dasm.decoded.each{|addr, di|
    @allintructionssize += di.bin_length
}

@allexecutablesize = 0
decodedfile.sections.each{|section|
    next if dasm.decoded.first == nil
    if section.characteristics.include? "CONTAINS_CODE" or section.characteristics.include? "MEM_EXECUTE"
        @allexecutablesize += section.encoded.data.length
    end
}

if (@allexecutablesize / @allintructionssize) > 3
    log("Packed : __YES__")
else
    log("Packed : __NO__")
end

repareIatLinks()

log("Sensitives functions called")
log("---------------------------")
dasm.xrefs.each{|addr, info|
    funcname = addr.to_s
    funcname = $gdasm.get_label_at(addr).gsub('iat_','') if defined?($gdasm.get_label_at(addr)) and $gdasm.get_label_at(addr) =~ /^iat_/
    
    if funcname =~ /^[0-9]+$/
        next
        dasm.each_xref(addr){|a|
            next
            di = dasm.di_at(a.origin)
            pp di if defined?(di.opcode) and di.opcode.name == "jmp"
            next
        }
    else
        if checkedFunc.include? funcname
            log("### API &lt;&lt; #{funcname} &gt;&gt; :")
            dasm.each_xref(addr){|a|
                xaddr = a
                xaddr = a.address if defined?(a.address)
                xaddr = a.origin if defined?(a.origin)
                di = dasm.di_at(xaddr)
                if defined?(di.opcode) and di.opcode.name == "jmp"
                    dasm.each_xref(di.address){|diprev|
                        checkCall(funcname, diprev.origin)
                        orifunc = find_start_of_function(diprev.origin)
                        if orifunc
                            entrypoints.each{|ep|
                                printCallTree(dasm.normalize(ep),orifunc) if isFuncTreeLink(dasm.normalize(ep),orifunc)
                            }
                        end
                    }
                elsif defined?(di.opcode) and di.opcode.name == "call"
                    checkCall(funcname, xaddr)
                    orifunc = find_start_of_function(xaddr)
                    if orifunc
                        entrypoints.each{|ep|
                            printCallTree(dasm.normalize(ep),orifunc) if isFuncTreeLink(dasm.normalize(ep),orifunc)
                        }
                    end
                else
                    checkCall(funcname, xaddr)
                    orifunc = find_start_of_function(xaddr)
                    if orifunc
                        entrypoints.each{|ep|
                            printCallTree(dasm.normalize(ep),orifunc) if isFuncTreeLink(dasm.normalize(ep),orifunc)
                        }
                    end
                end
            }
        end
    end
}

@instrAntiVM = []
@instrAntiDBG = []
strings = []
regexStr =  /(\.exe$|\.dll$|\.bat$|\.pif$|\.vbs$|\.cmd$|\.inf$|\.lnk|\.ocx$|\.tmp$|Software|Program|http)/
dasm.decoded.each{|addr, di|
    if (di.instruction.to_s =~ /(564d5868h|5658h)/ or di.opcode.name == 'sidt' or di.opcode.name == 'sgdt' or di.opcode.name == 'sldt' or di.opcode.name == 'str')
        @instrAntiVM << di
    end
    if (di.instruction.to_s =~ /(IsDebuggerPresent|cmp .*, 0CCh|pop ss|SeDebugPrivilege|IsBadWritePtr)/ or di.opcode.name == 'rtdsc')
        @instrAntiDBG << di
    end
    
    if di.opcode.name == 'push' and is_modrm(di.instruction.args.first)
        if di.instruction.args.first.symbolic.target.bind.reduce.to_s =~ /^[0-9]+$/
            dest = di.instruction.args.first.symbolic.target.bind.reduce
            argStr = dasm.decode_strz(dest)
            if argStr != nil and argStr.length > 4 and (argStr =~ regexStr or (argStr.length > 5 and not argStr =~ /[\x80-\xff]/n ))
                strings << [di.address, argStr.gsub(/[\x0d]/n, '\\r').gsub(/[\x0a]/n, '\\n')]
                next
            end
            argStr = dasm.decode_wstrz(dest)
            argStr = argStr.gsub(/[\x00]/n, '') if argStr != nil
            if argStr != nil and argStr.length > 4 and (argStr =~ regexStr or (argStr.length > 5 and not argStr =~ /[\x80-\xff]/n ))
                strings << [di.address, argStr.gsub(/[\x0d]/n, '\\r').gsub(/[\x0a]/n, '\\n')]
                next
            end
        end
    end
    if di.opcode.name == 'push' and di.instruction.args.first.to_s =~ /^(xref_|)[0-9a-f]+h$/
        argStr = dasm.decode_strz(di.instruction.args.first)
        if argStr != nil and argStr.length > 4 and (argStr =~ regexStr or (argStr.length > 5 and not argStr =~ /[\x80-\xff]/n ))
            strings << [di.address, argStr.gsub(/[\x0d]/n, '\\r').gsub(/[\x0a]/n, '\\n')]
            next
        end
        argStr = dasm.decode_wstrz(di.instruction.args.first)
        argStr = argStr.gsub(/[\x00]/n, '') if argStr != nil
        if argStr != nil and argStr.length > 4 and (argStr =~ regexStr or (argStr.length > 5 and not argStr =~ /[\x80-\xff]/n ))
            strings << [di.address, argStr.gsub(/[\x0d]/n, '\\r').gsub(/[\x0a]/n, '\\n')]
            next
        end
    end
    if di.opcode.name == 'mov' and is_modrm(di.instruction.args.last) and di.instruction.args.last.to_s =~ /dword ptr \[e.*\]/
        if di.instruction.args.last.symbolic.target.bind.reduce.to_s =~ /^[0-9]+$/
            dest = di.instruction.args.last.symbolic.target.bind.reduce
            argStr = dasm.decode_strz(dest)
            if argStr != nil and argStr.length > 4 and (argStr =~ regexStr or (argStr.length > 5 and not argStr =~ /[\x80-\xff]/n ))
                strings << [di.address, argStr.gsub(/[\x0d]/n, '\\r').gsub(/[\x0a]/n, '\\n')]
                next
            end
            argStr = dasm.decode_wstrz(dest)
            argStr = argStr.gsub(/[\x00]/n, '') if argStr != nil
            if argStr != nil and argStr.length > 4 and (argStr =~ regexStr or (argStr.length > 5 and not argStr =~ /[\x80-\xff]/n ))
                strings << [di.address, argStr.gsub(/[\x0d]/n, '\\r').gsub(/[\x0a]/n, '\\n')]
                next
            end
        end
    end
    if di.opcode.name == 'mov' and di.instruction.args.last.to_s =~ /^[(xref_|)0-9a-f]+h$/
        argStr = dasm.decode_strz(di.instruction.args.last)
        if argStr != nil and argStr.length > 4 and (argStr =~regexStr or (argStr.length > 5 and not argStr =~ /[\x80-\xff]/n ))
            strings << [di.address, argStr.gsub(/[\x0d]/n, '\\r').gsub(/[\x0a]/n, '\\n')]
            next
        end
        argStr = dasm.decode_wstrz(di.instruction.args.last)
        argStr = argStr.gsub(/[\x00]/n, '') if argStr != nil
        if argStr != nil and argStr.length > 4 and (argStr =~ regexStr or (argStr.length > 5 and not argStr =~ /[\x80-\xff]/n ))
            strings << [di.address, argStr.gsub(/[\x0d]/n, '\\r').gsub(/[\x0a]/n, '\\n')]
            next
        end
    end
}

strings = strings.sort.uniq

@strEXE = []
@strFIL = []
@strREG = []
@strWEB = []
@strDNS = []
@strAntiVM = []
@strAntiDBG = []
@strAntiAV = []
tmpstrings = []


movebpstack = []
dasm.decoded.each{|addr, di|
    if (di.instruction.to_s =~ /^mov .*\[ebp-[0-9a-f]*h{0,1}\], [0-9a-f]*h{0,1}$/n)
        movebpstack << di
    end
    if ((di.opcode.props[:setip] == true) or (di.opcode.props[:stopexec] == true)) and (movebpstack.length > 3)
        sizeMin = 0xffffff
        sizeMax = 0
        movebpstack.each{|tdi|
            cptr = -(tdi.instruction.args.first.symbolic.target.bind(:ebp => 0).reduce)
            sizeMin = cptr if sizeMin > cptr
            sizeMax = cptr if sizeMax < cptr
        }
        
        sizeTb = sizeMax-sizeMin
        ctb = "\x00"*(sizeTb)
        
        movebpstack.each{|tdi|
            ctb[sizeMax, tdi.instruction.args.first.sz/8]
            i=0
            strToInj = ""
            numToInj = $gdasm.normalize(tdi.instruction.args.last)
            while i<tdi.instruction.args.first.sz
                strToInj += [(numToInj&(0xff<<i))>>i].pack("c")
                i+=8
            end
            ctb[((sizeMax+(tdi.instruction.args.first.symbolic.target.bind(:ebp => 0).reduce))),strToInj.length] = strToInj
        }
        ctb += "\x00"
        tbstrings = []
        
        ctbptr = 1
        debstr = 0
        while ctbptr < ctb.length
            if (ctb[ctbptr] == "\x00") and (ctb[ctbptr-1] != "\x00")
                movebpstack.each{|tdi|
                    if (tdi.instruction.args.first.symbolic.target.bind(:ebp => 0).reduce < -(sizeMax-(debstr+tdi.instruction.args.first.sz/8))) and (tdi.instruction.args.first.symbolic.target.bind(:ebp => 0).reduce >= -(sizeMax-(debstr)))
                        if (not ctb[debstr,ctbptr-debstr] =~ /([\x7f-\xff]|[\x01-\x08]|[\x0b-\x1f])/n) and ctb[debstr,ctbptr-debstr].length > 4
                            tbstrings << [tdi.address, ctb[debstr,ctbptr-debstr]]
                        end
                    end
                }
            end
            debstr = ctbptr if (ctb[ctbptr] != "\x00") and (ctb[ctbptr-1] == "\x00")
            ctbptr += 1
        end
        
        if tbstrings.length > 0
            log("### Rebuilded strings :")
            log("")
            tbstrings.each{|caddr,cstring|
                strings << [caddr, cstring]
                log("  *   #{poliLinkAddr(caddr)} : \"#{cstring}\"")
                @tbComments[caddr] = "Builded string : \\\"#{cstring.gsub("\n","\\n")}\\\""
            }
            log("")
        end
    end
    movebpstack = [] if ((di.opcode.props[:setip] == true) or (di.opcode.props[:stopexec] == true))
}

strings.each{|addr, str|
    tmpstrings << [addr, str]
}

tmpstrings.each{|addr, str|
    if str.length < 5 or str =~ /([\x7f-\xff]|[\x01-\x08]|[\x0b-\x1f])/n
        strings.delete([addr, str])
        next
    end
    if str =~ /(<|>)/
        strings.delete([addr, str])
        str = str.gsub("<","&lt;").gsub(">","&gt;")
        strings << [addr, str]
    end
    if str.downcase =~ /(\.exe$|\.dll$|\.bat$|\.pif$|\.vbs$|\.cmd$|\.sys$|\.ocx$)/
        @strEXE << [addr, str]
        strings.delete([addr, str])
    end
    if str.downcase =~ /(\.inf$|\.lnk$|\.tmp$|\.ini$)/
        @strFIL << [addr, str]
        strings.delete([addr, str])
    end
    if str.downcase =~ /(software\\|system\\|microsoft\\|currentcontrolset)/
        @strREG << [addr, str]
        strings.delete([addr, str])
    end
    if str.downcase =~ /(http[s]{0,1}:\/\/|get |post |\/[a-z0-9\/.]{0,}\?[0-9a-z]+|http\/[0-9]\.[0-9])/
        @strWEB << [addr, str]
        strings.delete([addr, str])
    end
    if str.downcase =~ /(vmscsi\.sys|vmhgfs\.sys|vmx_svga\.sys|vmxnet\.sys|vmmouse\.sys|vmdebug\.sys|vmware|sbiedll|qemu|wine_get_unix_file_name|vbox|virtualbox)/
        @strAntiVM << [addr, str]
        strings.delete([addr, str])
    end
    if str.downcase =~ /(isdebuggerpresent|sedebugprivilege|\\\\.\\extrem|\\\\.\\filem|\\\\.\\filevxg|\\\\.\\iceext|\\\\.\\ndbgmsg.vxd|\\\\.\\ntice|\\\\.\\regsys|\\\\.\\regvxg|\\\\.\\ring0|\\\\.\\sice|\\\\.\\siwvid|\\\\.\\trw|\\\\.\\spcommand|\\\\.\\syser|\\\\.\\syserdbgmsg|\\\\.\\syserlanguage|softice|checkremotedebuggerpresent|dbgbreakpoint|ollydbg|windbgframeclass|zeta debugger|rock debugger|obsidiangui|ollyice|filemon|windbg|procmon|wireshark|procexp|taskmgr)/
        @strAntiDBG << [addr, str]
        strings.delete([addr, str])
    end
    if str.downcase =~ /(kaspersky|norton|clamav|avast|bitdef|outpost|avira|antivir|comodo|drweb|eset|mcafee|sophos)/
        @strAntiAV << [addr, str]
        strings.delete([addr, str])
    end
    if str.downcase =~ /(\.arpa$|\.com$|\.edu$|\.firm$|\.gov$|\.int$|\.mil$|\.mobi$|\.nato$|\.net$|\.nom$|\.org$|\.store$|\.web$|\.ac$|\.ad$|\.ae$|\.af$|\.ag$|\.ai$|\.al$|\.am$|\.an$|\.ao$|\.aq$|\.ar$|\.as$|\.at$|\.au$|\.aw$|\.az$|\.ba$|\.bb$|\.bd$|\.be$|\.bf$|\.bg$|\.bh$|\.bi$|\.bj$|\.bm$|\.bn$|\.bo$|\.br$|\.bs$|\.bt$|\.bv$|\.bw$|\.by$|\.bz$|\.ca$|\.cc$|\.cf$|\.cg$|\.ch$|\.ci$|\.ck$|\.cl$|\.cm$|\.cn$|\.co$|\.cr$|\.cs$|\.cu$|\.cv$|\.cx$|\.cy$|\.cz$|\.de$|\.dj$|\.dk$|\.dm$|\.do$|\.dz$|\.ec$|\.ee$|\.eg$|\.eh$|\.er$|\.es$|\.et$|\.eu$|\.fi$|\.fj$|\.fk$|\.fm$|\.fo$|\.fr$|\.fx$|\.ga$|\.gb$|\.gd$|\.ge$|\.gf$|\.gh$|\.gi$|\.gl$|\.gm$|\.gn$|\.gp$|\.gq$|\.gr$|\.gs$|\.gt$|\.gu$|\.gw$|\.gy$|\.hk$|\.hm$|\.hn$|\.hr$|\.ht$|\.hu$|\.id$|\.ie$|\.il$|\.in$|\.io$|\.iq$|\.ir$|\.is$|\.it$|\.jm$|\.jo$|\.jp$|\.ke$|\.kg$|\.kh$|\.ki$|\.km$|\.kn$|\.kp$|\.kr$|\.kw$|\.ky$|\.kz$|\.la$|\.lb$|\.lc$|\.li$|\.lk$|\.lr$|\.ls$|\.lt$|\.lu$|\.lv$|\.ly$|\.ma$|\.mc$|\.md$|\.mg$|\.mh$|\.mk$|\.ml$|\.mm$|\.mn$|\.mo$|\.mp$|\.mq$|\.mr$|\.ms$|\.mt$|\.mu$|\.mv$|\.mw$|\.mx$|\.my$|\.mz$|\.na$|\.nc$|\.ne$|\.nf$|\.ng$|\.ni$|\.nl$|\.no$|\.np$|\.nr$|\.nt$|\.nu$|\.nz$|\.om$|\.pa$|\.pe$|\.pf$|\.pg$|\.ph$|\.pk$|\.pl$|\.pm$|\.pn$|\.pr$|\.pt$|\.pw$|\.py$|\.qa$|\.re$|\.ro$|\.ru$|\.rw$|\.sa$|\.sb$|\.sc$|\.sd$|\.se$|\.sg$|\.sh$|\.si$|\.sj$|\.sk$|\.sl$|\.sm$|\.sn$|\.so$|\.sr$|\.st$|\.su$|\.sv$|\.sy$|\.sz$|\.tc$|\.td$|\.tf$|\.tg$|\.th$|\.tj$|\.tk$|\.tm$|\.tn$|\.to$|\.tp$|\.tr$|\.tt$|\.tv$|\.tw$|\.tz$|\.ua$|\.ug$|\.uk$|\.um$|\.us$|\.uy$|\.uz$|\.va$|\.vc$|\.ve$|\.vg$|\.vi$|\.vn$|\.vu$|\.wf$|\.ws$|\.ye$|\.yt$|\.yu$|\.za$|\.zm$|\.zr$|\.zw$)/
        @strDNS << [addr, str]
        strings.delete([addr, str])
    end
}

if (@instrAntiDBG.length > 0)
    log("\nListe instructions suceptible de detecter la presence d'un debugger :")
    log ("")
    @instrAntiDBG.each{|di|
        log("  * #{poliLinkAddr(di.address)} '#{di.instruction.to_s}'")
        @tbComments[di.address] = "Anti-dbg ?"
    }
    log("")
end

if (@instrAntiVM.length > 0)
    log("\nAnti-VM instructions :")
    log("")
    @instrAntiVM.each{|di|
        log("  * #{poliLinkAddr(di.address)} '#{di.instruction.to_s}'")
        @tbComments[di.address] = "Anti-VM ?"
    }
    log("")
end

log("Crypto")
log("------")

dasm.sections.each{|secAddr, secDatas|
    cryptoPatterns.each{|name, patterns|
        ok = 0
        pattAddr = 0
        for pattern in patterns
            if secDatas.data[0..-1].index(pattern) != nil
                ok = 1
                pattAddr = secAddr+secDatas.data[0..-1].index(pattern)
            end
        end
        if ok == 1
            log("\nPattern affected to #{name} found at #{poliLinkAddr(pattAddr)}.")
            @tbComments[pattAddr] = "Crypto #{name} ?"
            orifunc = find_start_of_function(pattAddr)
            if orifunc
                log("Function : #{poliLinkAddr(orifunc)}.")
                if orifunc != 0
                    AddTagFunction(orifunc, "Crypt_")
                end
                if isFuncTreeLink(dasm.normalize(entrypoints),orifunc)
                    printCallTree(dasm.normalize(entrypoints),orifunc)
                else
                    @treefuncs.each{|addr, toaddr, fromaddr|
                        if addr == orifunc
                            log("")
                            fromaddr.each{|ref_from|
                                log("  * #{poliLinkAddr(ref_from)} call #{poliLinkAddr(orifunc)}.")
                            }
                            log("")
                        end
                    }
                end
            end
        end
    }
}

@CryptoBlocks = []

dasm.decoded.each{|addr, di|
    if di.opcode.name == 'xor' and di.instruction.args.first.to_s != di.instruction.args.last.to_s and is_looping(di)
        next if @CryptoBlocks.include? di.block.address
        @CryptoBlocks << di.block.address
        next if di.instruction.args.last.to_s == "-1"
        if di.block.to_normal.include? di.block.address
            log("\nPotential crypto loop :")
            @tbComments[di.address] = "Crypto loop ?"
            log("\n")
            di.block.list.each{|tdi|
                log("    #{tdi.to_s()}")
            }
            log("\n")
            orifunc = find_start_of_function(di.address)
            if orifunc
                log("Top function #{poliLinkAddr(orifunc)}.")
                if orifunc != 0
                    AddTagFunction(orifunc, "Crypt_")
                end
                @treeloop = 0
                entrypoints.each{|ep|
                    if isFuncTreeLink(dasm.normalize(ep),orifunc)
                        printCallTree(dasm.normalize(ep),orifunc)
                        @treeloop = 1
                    end
                }
                if @treeloop == 0
                    @treefuncs.each{|addr, toaddr, fromaddr|
                        if addr == orifunc
                            log("")
                            fromaddr.each{|ref_from|
                                log("  *   #{poliLinkAddr(ref_from)} call #{poliLinkAddr(orifunc)}.")
                            }
                            log("")
                        end
                    }
                end
            end
        else
            log("\nPotential crypto loop at #{poliLinkAddr(di.address)} '#{di.instruction.to_s}'")
            @tbComments[di.address] = "Crypto loop ?"
            orifunc = find_start_of_function(di.address)
            if orifunc
                log("top function #{poliLinkAddr(orifunc)}.")
                if orifunc != 0
                    AddTagFunction(orifunc, "Crypt_")
                end
                @treeloop = 0
                entrypoints.each{|ep|
                    if isFuncTreeLink(dasm.normalize(ep),orifunc)
                        printCallTree(dasm.normalize(ep),orifunc)
                        @treeloop = 1
                    end
                }
                if @treeloop == 0
                    @treefuncs.each{|addr, toaddr, fromaddr|
                        if addr == orifunc
                            log("")
                            fromaddr.each{|ref_from|
                                log("  *   #{poliLinkAddr(ref_from)} call #{poliLinkAddr(orifunc)}.")
                            }
                            log("")
                        end
                    }
                end
            end
        end
    end
}


log("Strings")
log("-------")

if (@strAntiVM.length > 0)
    log("\n### Anti-VM")
    log("")
    @strAntiVM.each{|addr, str|
        basefunc = find_start_of_function(addr)
        basefunc = 0 if basefunc == nil
        if defined?($gdasm.di_at(addr).block) and defined?($gdasm.di_at(addr).block.list[0]) and defined?($gdasm.di_at(addr).block.list[0].address)
            tbloc = $gdasm.di_at(addr).block.list[0].address
        else
            tbloc = 0
        end
        log("  *   '#{str}'")
        log("    * instr : #{poliLinkAddr(addr)} ; block : #{poliLinkAddr(tbloc)} ; function : #{poliLinkAddr(basefunc)}")
    }
end

if (@strAntiDBG.length > 0)
    log("\n### Anti-Debug")
    log("")
    @strAntiDBG.each{|addr, str|
        basefunc = find_start_of_function(addr)
        basefunc = 0 if basefunc == nil
        if defined?($gdasm.di_at(addr).block) and defined?($gdasm.di_at(addr).block.list[0]) and defined?($gdasm.di_at(addr).block.list[0].address)
            tbloc = $gdasm.di_at(addr).block.list[0].address
        else
            tbloc = 0
        end
        log("  *   '#{str}'")
        log("    * instr : #{poliLinkAddr(addr)} ; block : #{poliLinkAddr(tbloc)} ; function : #{poliLinkAddr(basefunc)}")
        @tbComments[di.address] = "Anti-dbg ?"
    }
end

if (@strAntiAV.length > 0)
    log("\n### Anti-AV")
    log("")
    @strAntiAV.each{|addr, str|
        basefunc = find_start_of_function(addr)
        basefunc = 0 if basefunc == nil
        if defined?($gdasm.di_at(addr).block) and defined?($gdasm.di_at(addr).block.list[0]) and defined?($gdasm.di_at(addr).block.list[0].address)
            tbloc = $gdasm.di_at(addr).block.list[0].address
        else
            tbloc = 0
        end
        log("  *   '#{str}'")
        log("    * instr : #{poliLinkAddr(addr)} ; block : #{poliLinkAddr(tbloc)} ; function : #{poliLinkAddr(basefunc)}")
        @tbComments[di.address] = "Anti-VM ?"
    }
end

if (@strEXE.length > 0)
    log("\n### Executables")
    log("")
    @strEXE.each{|addr, str|
        basefunc = find_start_of_function(addr)
        basefunc = 0 if basefunc == nil
        if defined?($gdasm.di_at(addr).block) and defined?($gdasm.di_at(addr).block.list[0]) and defined?($gdasm.di_at(addr).block.list[0].address)
            tbloc = $gdasm.di_at(addr).block.list[0].address
        else
            tbloc = 0
        end
        log("  *   '#{str}'")
        log("    *   instr : #{poliLinkAddr(addr)} ; block : #{poliLinkAddr(tbloc)} ; function : #{poliLinkAddr(basefunc)}")
    }
end

if (@strREG.length > 0)
    log("\n### Registry")
    log("")
    @strREG.each{|addr, str|
        basefunc = find_start_of_function(addr)
        basefunc = 0 if basefunc == nil
        if defined?($gdasm.di_at(addr).block) and defined?($gdasm.di_at(addr).block.list[0]) and defined?($gdasm.di_at(addr).block.list[0].address)
            tbloc = $gdasm.di_at(addr).block.list[0].address
        else
            tbloc = 0
        end
        log("  *   '#{str}'")
        log("    * instr : #{poliLinkAddr(addr)} ; block : #{poliLinkAddr(tbloc)} ; function : #{poliLinkAddr(basefunc)}")
}
end

if (@strWEB.length > 0)
    log("\n### Web")
    log("")
    @strWEB.each{|addr, str|
        basefunc = find_start_of_function(addr)
        basefunc = 0 if basefunc == nil
        if defined?($gdasm.di_at(addr).block) and defined?($gdasm.di_at(addr).block.list[0]) and defined?($gdasm.di_at(addr).block.list[0].address)
            tbloc = $gdasm.di_at(addr).block.list[0].address
        else
            tbloc = 0
        end
        log("  *   '#{str}'")
        log("    * instr : #{poliLinkAddr(addr)} ; block : #{poliLinkAddr(tbloc)} ; function : #{poliLinkAddr(basefunc)}")
    }
end

if (@strDNS.length > 0)
    log("\n### DNS")
    log("")
    @strDNS.each{|addr, str|
        basefunc = find_start_of_function(addr)
        basefunc = 0 if basefunc == nil
        if defined?($gdasm.di_at(addr).block) and defined?($gdasm.di_at(addr).block.list[0]) and defined?($gdasm.di_at(addr).block.list[0].address)
            tbloc = $gdasm.di_at(addr).block.list[0].address
        else
            tbloc = 0
        end
        log("  *   '#{str}'")
        log("    * instr : #{poliLinkAddr(addr)} ; block : #{poliLinkAddr(tbloc)} ; function : #{poliLinkAddr(basefunc)}")
    }
end

if (@strFIL.length > 0)
    log("\n### Files")
    log("")
    @strFIL.each{|addr, str|
        basefunc = find_start_of_function(addr)
        basefunc = 0 if basefunc == nil
        if defined?($gdasm.di_at(addr).block) and defined?($gdasm.di_at(addr).block.list[0]) and defined?($gdasm.di_at(addr).block.list[0].address)
            tbloc = $gdasm.di_at(addr).block.list[0].address
        else
            tbloc = 0
        end
        log("  *   '#{str}'")
        log("    * instr : #{poliLinkAddr(addr)} ; block : #{poliLinkAddr(tbloc)} ; function : #{poliLinkAddr(basefunc)}")
    }
end

if (strings.length > 0)
    log("\n### Unclassified")
    log("")
    strings.each{|addr, str|
        basefunc = find_start_of_function(addr)
        basefunc = 0 if basefunc == nil
        if defined?($gdasm.di_at(addr).block) and defined?($gdasm.di_at(addr).block.list[0]) and defined?($gdasm.di_at(addr).block.list[0].address)
            tbloc = $gdasm.di_at(addr).block.list[0].address
        else
            tbloc = 0
        end
        next if str =~ /([\x7f-\xff]|[\x01-\x08]|[\x0b-\x1f])/n
        log("  *   '#{str}'")
        log("    * instr : #{poliLinkAddr(addr)} ; block : #{poliLinkAddr(tbloc)} ; function : #{poliLinkAddr(basefunc)}")
    }
end


@fullFuncSign = ""
@fullHashSign = ""
dasm.function.each{|addr, symb|
    @listoffunct << addr if addr.to_s =~ /^[0-9]+$/
}
@listoffunct = @listoffunct.sort
@listoffunct .each{|addr|
    if addr.to_s =~ /^[0-9]+$/
        i = 1
        currFunc = ""
        @treefunc = dasm.each_function_block(addr)
        @treefunc = @treefunc.sort
        @treetbfunc = []
        c = 1
        @treefunc.each{|b|
            @treetbfunc << b
        }
        @treefunc.each{|bloc|
            currFunc += "#{i.to_s()}:"
            dasm.di_at(bloc[0]).block.list.each{|di|
                currFunc += "," if di.opcode.name == 'call' and currFunc[-1] == 'c'
                currFunc += "c" if di.opcode.name == 'call'
            }
            refs = bloc[1]
            refs = refs.sort
            refs.each{|to_ref|
                for y in 0..@treetbfunc.length
                    next if @treetbfunc[y] == nil
                    currFunc += "," if to_ref == @treetbfunc[y][0] and currFunc[-1] != ',' and currFunc[-1] != ':'
                    currFunc += "#{(y+1).to_s()}" if to_ref == @treetbfunc[y][0]
                end
            }
            i += 1
            currFunc += ";"
        }
        @fullFuncSign += currFunc
        @fullHashSign += ("%08x" % murmur3_32_str_hash(currFunc))+":#{addr.to_s(16)};"
    end
}

if not defined?($SIMPLE)
    @signfile = File.open("#{target}.sign", "wb")
    @signfile.write(@fullHashSign)
    @signfile.close()
end

time = Time.new

@tbFuncName.each{|cFuncAddr, cName|
    # if ori_renamed_functions[cFuncAddr] == nil
        # mysqlClient.query("INSERT INTO #{dbName}.ida_cmd VALUES ('', '#{opts[:idMalware]}','#{ida_cmd_type_name['idc.MakeName']}', '0x#{cFuncAddr.to_s(16)}', '#{cName}', 0, 2)")
    # end
    @IDAscript += "idc.MakeName::0x#{cFuncAddr.to_s(16)}::#{cName}\n"
}

@tbComments.each{|addr, cComment|
    # if ori_comments[addr] == nil
        # mysqlClient.query("INSERT INTO #{dbName}.ida_cmd VALUES ('', '#{opts[:idMalware]}','#{ida_cmd_type_name['idc.MakeRptCmt']}', '0x#{addr.to_s(16)}', '#{cComment}', 0, 2)")
    # end
    @IDAscript += "idc.MakeRptCmt::0x#{addr.to_s(16)}::#{cComment}\n"
}

if not File.exist?("#{target}.idacmd") and (not defined?($SIMPLE))
    File.open("#{target}.idacmd", 'wb') { |file| file.write("#{@IDAscript}nop() # Polichombr 1337 - Skelenox 1337 too ;]") }
end

# pp dasm.program.methods
# Gui::DasmWindow.new("metasm disassembler - #{target}", dasm, entrypoints)
# dasm.load_plugin('hl_opcode')	# hilight jmp/call instrs
# dasm.gui.focus_addr(dasm.gui.curaddr, :graph)	# start in graph mode
# Gui.main
if not defined?($SIMPLE)
    @file.write("\n")
    @file.close
end

if $SHOWGUI
    Gui::DasmWindow.new("metasm disassembler - #{target}", dasm, entrypoints)
    dasm.load_plugin('hl_opcode')	# hilight jmp/call instrs
    dasm.gui.focus_addr(dasm.gui.curaddr, :graph)	# start in graph mode
    Gui.main
end
