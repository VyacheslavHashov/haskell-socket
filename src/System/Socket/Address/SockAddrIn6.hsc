module System.Socket.Address.SockAddrIn6
  ( SockAddrIn6 (..)
  ) where

import Data.Word
import qualified Data.ByteString as BS
import qualified Data.ByteString.Unsafe as BS

import Foreign.Ptr
import Foreign.Storable
import Foreign.Marshal.Utils

import System.Socket.Address

#include "sys/types.h"
#include "sys/socket.h"
#include "sys/un.h"
#include "netinet/in.h"
#let alignment t = "%lu", (unsigned long)offsetof(struct {char x__; t (y__); }, y__)

instance Address SockAddrIn6 where
  addressFamilyNumber _ = (#const AF_INET6)

data SockAddrIn6
   = SockAddrIn6
     { sin6Port      :: Word16
     , sin6Flowinfo  :: Word32
     , sin6Addr      :: BS.ByteString
     , sin6ScopeId   :: Word32
     } deriving (Eq, Ord)

instance Show SockAddrIn6 where
  show (SockAddrIn6 p _ a _) = '"':'[':(tail $ t $ BS.unpack a)
    where
      t []       = ']':':':(show p ++ "\"")
      t [x]      = g x 0 (']':':':(show p) ++ "\"")
      t (x:y:xs) = g x y (t xs)
      g x y s    = let (a,b) = quotRem x 16
                       (c,d) = quotRem y 16
                   in  ':':(h a):(h b):(h c):(h d):s
      h 0  = '0'
      h 1  = '1'
      h 2  = '2'
      h 3  = '3'
      h 4  = '4'
      h 5  = '5'
      h 6  = '6'
      h 7  = '7'
      h 8  = '8'
      h 9  = '9'
      h 10 = 'a'
      h 11 = 'b'
      h 12 = 'c'
      h 13 = 'd'
      h 14 = 'e'
      h 15 = 'f'
      h  _ = '_'

instance Storable SockAddrIn6 where
  sizeOf    _ = (#size struct sockaddr_in6)
  alignment _ = (#alignment struct sockaddr_in6)
  peek ptr    = do
    f   <- peek              (sin6_flowinfo ptr) :: IO Word32
    ph  <- peekByteOff       (sin6_port ptr)  0  :: IO Word8
    pl  <- peekByteOff       (sin6_port ptr)  1  :: IO Word8
    a   <- BS.packCStringLen (sin6_addr ptr, 16) :: IO BS.ByteString
    s   <- peek              (sin6_scope_id ptr) :: IO Word32
    return (SockAddrIn6 (fromIntegral ph * 256 + fromIntegral pl) f a s)
    where
      sin6_flowinfo = (#ptr struct sockaddr_in6, sin6_flowinfo)
      sin6_scope_id = (#ptr struct sockaddr_in6, sin6_scope_id)
      sin6_port     = (#ptr struct sockaddr_in6, sin6_port)
      sin6_addr     = (#ptr struct in6_addr, s6_addr) . (#ptr struct sockaddr_in6, sin6_addr)
  poke ptr (SockAddrIn6 p f a s) = do
    poke        (sin6_family   ptr) ((#const AF_INET6) :: Word16)
    poke        (sin6_flowinfo ptr) f
    poke        (sin6_scope_id ptr) s
    pokeByteOff (sin6_port     ptr)  0 (fromIntegral $ rem (quot p 256) 256 :: Word8)
    pokeByteOff (sin6_port     ptr)  1 (fromIntegral $ rem       p      256 :: Word8)
    BS.unsafeUseAsCString a $ \a'-> do
      copyBytes (sin6_addr ptr) a' (min 16 $ BS.length a)-- copyBytes dest from count
    where
      sin6_family   = (#ptr struct sockaddr_in6, sin6_family)
      sin6_flowinfo = (#ptr struct sockaddr_in6, sin6_flowinfo)
      sin6_scope_id = (#ptr struct sockaddr_in6, sin6_scope_id)
      sin6_port     = (#ptr struct sockaddr_in6, sin6_port)
      sin6_addr     = (#ptr struct in6_addr, s6_addr) . (#ptr struct sockaddr_in6, sin6_addr)