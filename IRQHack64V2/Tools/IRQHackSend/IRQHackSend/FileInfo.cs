using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace IRQHackSend
{
    struct DirEntry
    {
    //    /*
    //    struct directoryEntry {
    //      /** Short 8.3 name.
    //       *
    //       * The first eight bytes contain the file name with blank fill.
    //       * The last three bytes contain the file extension with blank fill.
    //       */
    //    uint8_t name[11];
    //    /** Entry attributes.
    //     *
    //     * The upper two bits of the attribute byte are reserved and should
    //     * always be set to 0 when a file is created and never modified or
    //     * looked at after that.  See defines that begin with DIR_ATT_.
    //     */
    //    uint8_t attributes;
    //    /**
    //     * Reserved for use by Windows NT. Set value to 0 when a file is
    //     * created and never modify or look at it after that.
    //     */
    //    uint8_t reservedNT;
    //    /**
    //     * The granularity of the seconds part of creationTime is 2 seconds
    //     * so this field is a count of tenths of a second and its valid
    //     * value range is 0-199 inclusive. (WHG note - seems to be hundredths)
    //     */
    //    uint8_t creationTimeTenths;
    //    /** Time file was created. */
    //    uint16_t creationTime;
    //    /** Date file was created. */
    //    uint16_t creationDate;
    //    /**
    //     * Last access date. Note that there is no last access time, only
    //     * a date.  This is the date of last read or write. In the case of
    //     * a write, this should be set to the same date as lastWriteDate.
    //     */
    //    uint16_t lastAccessDate;
    //    /**
    //     * High word of this entry's first cluster number (always 0 for a
    //     * FAT12 or FAT16 volume).
    //     */
    //    uint16_t firstClusterHigh;
    //    /** Time of last write. File creation is considered a write. */
    //    uint16_t lastWriteTime;
    //    /** Date of last write. File creation is considered a write. */
    //    uint16_t lastWriteDate;
    //    /** Low word of this entry's first cluster number. */
    //    uint16_t firstClusterLow;
    //    /** 32-bit unsigned holding this file's size in bytes. */
    //    uint32_t fileSize;
    //} __attribute__((packed));

    }
    class FileInfo
    {
    }
}
