/**
 * @file MultiClampTelegraph.cpp
 *
 * @brief State storage and message processing for Axon MutliClamp 700A/700B amplifiers.
 *
 * A formal window is spawned, to recieve responsese from the MutltiClamp Commander program, which is where the
 * information originates. Connection is initiated by this code, via a broadcast message. Responses will then come
 * either as broadcast messages or as messages targeted directly at this window. The window is not visible or
 * accessible to the user in any way. It is intended solely for message processing, but it is not a message-class
 * window, as message windows do not recieve broadcast messages. The message processing requires a thread to
 * poll for new messages.
 *
 * A continually growing global array of states is maintained, with one state structure for each amplifier/channel. In
 * practice, this array will rarely grow beyond two entries. Old states are maintained even if an amplifier is off, so
 * the states may be stale. We can't know if an amplifier goes off line anyway. This means that the user level code needs 
 * to understand that queries may produce stale data. This is okay, since the previous user code (\@multi_clamp) expected
 * potentially stale data in the text file that was used for communication. Note that the global array is cleared if 
 * the mex file is cleared, as per good Matlab programming practice.
 *
 * While this is a 'cpp' file, because the Microsoft compiler chokes on an unadulterated MultiClampBroadcastMsg.hpp,
 * the code within here should be pure ANSI C (C99).
 *
 * @see http://msdn.microsoft.com/en-us/library/ms632596(VS.85).aspx
 * @see \htmlonly <a href="../../../resources/MCTG_Spec.pdf">MCTG_Spec.pdf</a> \endhtmlonly
 *
 * @author Timothy O'Connor
 * @date 10/26/08
 *
 * <em><b>Copyright</b> - Cold Spring Harbor Laboratories/Howard Hughes Medical Institute 2008</em>
 *
 */
 
 #ifdef MCT_DEBUG
   #pragma message("   *****   Compiling in debug mode.   *****")
 #endif

/*********************************
 *         OS DEFINES            *
 *********************************/
 /**
  * @brief This is required to use functions such as SwitchToThread.
  *
  * This declares that the minumum system used must be NT4.0.
  *
  * @see http://msdn.microsoft.com/en-us/library/ms686352.aspx
  */
#define _WIN32_WINNT 0x0400
 
/*********************************
 *     APPLICATION DEFINES       *
 *********************************/
 ///@brief The version number. This should be incremented when this file is changed.
#define MCT_VERSION "0.2"
 ///@brief This string is used in place of fields not supported by the 700A.
#define UNSPECIFIED_FOR_700A "UNSPECIFIED"
///@brief This string is used as the class name for the messaging window.
#define MCT_WINDOWCLASS_NAME "MCT_windowClass"
 
/*********************************
 *           INCLUDES            *
 *********************************/

#include "windows.h"
#ifdef MATLAB_MEX_FILE
  #include <mex.h>
#else
  #include "stdio.h"
#endif
#include <MultiClampBroadcastMsg.hpp>

/*********************************
 *      MACRO DEFINITIONS        *
 *********************************/
#ifndef MCT_DEBUG
   ///@brief Use printf semantics to display a debug message, if MCT_DEBUG is defined at compile-time.
   #define MCT_debugMsg(...)
#endif

#ifdef MATLAB_MEX_FILE
  ///@brief Use printf semantics to display a message to the console.
  #define MCT_printMsg(...)            mexPrintf(__VA_ARGS__)
  ///@brief Use printf/mexPrintf semantics to display an error message to the console.
  #define MCT_errorMsg(...)    mexPrintf("MCT_ERROR: " __VA_ARGS__)
  //It would be nice to use mexErrMsgTxt, but that may cause problems when called from the 
  //message processing thread, because it attempts to terminate the mex file.
  //#define MCT_errorMsg(...)    mexErrMsgTxt("MCT_ERROR: " __VA_ARGS__)
  #ifdef MCT_DEBUG
     ///@brief Use printf/mexPrintf  semantics to display a debug message, if MCT_DEBUG is defined at compile-time.
     #define MCT_debugMsg(...) mexPrintf("MCT_DEBUG: " __VA_ARGS__)
  #endif
#else
  ///@brief Use printf/mexPrintf  semantics to display a message to the console.
  #define MCT_printMsg(...)    printf(__VA_ARGS__)
  ///@brief Use printf semantics to display an error message to the console.
  #define MCT_errorMsg(...)    printf("MCT_ERROR: " __VA_ARGS__)
  #ifdef MCT_DEBUG
     ///@brief Use printf semantics to display a debug message, if MCT_DEBUG is defined at compile-time.
     #define MCT_debugMsg(...) printf("MCT_DEBUG: " __VA_ARGS__)
  #endif
#endif

/*********************************
 *       TYPE DEFINITIONS        *
 *********************************/

/**
 * @brief A representation of an amplifier/channel state.
 *
 * Each callback is identified by a unique ID, which also serves as its address for communcation purposes.
 */
typedef struct
{
   ///Unique identifier for, and address of, this amplifier/channel.
   LPARAM ID;
   /**
    * @brief Operating mode of the amplifier.
    *
    * The available modes are -\n
    *  @indent V-Clamp\n
    *  @indent I-Clamp\n
    *  @indent I = 0\n
    *
    * The unsigned integer is interpreted as an offset into the MCTG_MODE_NAMES array of strings.
    *
    * @see MCTG_MODE_NAMES
    */
   unsigned int uOperatingMode;
   /**
    * @brief Signal identifier of scaled (primary) output.
    *
    * 700A Values:\n
    *   @indent Membrane Potential / Command Current\n
    *   @indent Membrane Current\n
    *   @indent Pipette Potential / Membrane Potential\n
    *   @indent x100 AC Pipette / Membrane Potential\n
    *   @indent Bath Current\n
    *   @indent Bath Potential\n
    * 700B Values:\n
    *   @indent Membrane Current\n
    *   @indent Membrane Potential\n
    *   @indent Pipette Potential\n
    *   @indent 100x AC Membrane Potential\n
    *   @indent Command Current\n
    *   @indent External Command Potential / External Command Current\n
    *   @indent Auxiliary 1\n
    *   @indent Auxiliary 2\n
    */
   unsigned int uScaledOutSignal;
   ///@brief Gain of scaled (primary) output.
   double dAlpha;
   ///@brief Scale factor of scaled (primary) output.
   double dScaleFactor;
   /**
    * @brief Scale factor units of scaled (primary) output.
    *
    *  Values:\n
    *    @indent V/V  - MCTG_UNITS_VOLTS_PER_VOLT\n
    *    @indent V/mV - MCTG_UNITS_VOLTS_PER_MILLIVOLT\n
    *    @indent V/uV - MCTG_UNITS_VOLTS_PER_MICROVOLT\n
    *    @indent V/A  - MCTG_UNITS_VOLTS_PER_AMP\n
    *    @indent V/mA - MCTG_UNITS_VOLTS_PER_MILLIAMP\n
    *    @indent V/uA - MCTG_UNITS_VOLTS_PER_MICROAMP\n
    *    @indent V/nA - MCTG_UNITS_VOLTS_PER_NANOAMP\n
    *    @indent V/pA - MCTG_UNITS_VOLTS_PER_PICOAMP\n
    *    @indent None - MCTG_UNITS_NONE\n
    */
   unsigned int uScaleFactorUnits;
   ///@brief Lowpass filter cutoff frequency [Hz] of scaled (primary) output.
   double dLPFCutoff;
   ///@brief Membrane capacitance [F].
   double dMembraneCap;
   /**
    * @brief External command sensitivity.
    *
    *  Values:\n
    *    @indent V/V (V-Clamp)\n
    *    @indent A/V (I-Clamp)\n
    *    @indent 0.0 A/V, OFF (I=0)\n
    */
   double dExtCmdSens;
   /**
    * @brief Signal identifier of raw (secondary) output.
    *
    * 700A Values:\n
    *   @indent Membrane plus Offset Potential / Command Current\n
    *   @indent Membrane Current\n
    *   @indent Pipette Potential / Membrane plus Offset Potential\n
    *   @indent x100 AC Pipette / Membrane Potential\n
    *   @indent Bath Current\n
    *   @indent Bath Potential\n
    * 700B Values:\n
    *   @indent Membrane Current\n
    *   @indent Membrane Potential\n
    *   @indent Pipette Potential\n
    *   @indent 100x AC Membrane Potential\n
    *   @indent External Command Potential / External Command Current\n
    *   @indent Auxiliary 1\n
    *   @indent Auxiliary 2\n
    */
   unsigned int uRawOutSignal;
   ///@brief Scale factor of raw (secondary) output.
   double dRawScaleFactor;
   /**
    * @brief Scale factor units of raw (secondary) output.
    *
    *  Values:\n
    *    @indent V/V  - MCTG_UNITS_VOLTS_PER_VOLT\n
    *    @indent V/mV - MCTG_UNITS_VOLTS_PER_MILLIVOLT\n
    *    @indent V/uV - MCTG_UNITS_VOLTS_PER_MICROVOLT\n
    *    @indent V/A  - MCTG_UNITS_VOLTS_PER_AMP\n
    *    @indent V/mA - MCTG_UNITS_VOLTS_PER_MILLIAMP\n
    *    @indent V/uA - MCTG_UNITS_VOLTS_PER_MICROAMP\n
    *    @indent V/nA - MCTG_UNITS_VOLTS_PER_NANOAMP\n
    *    @indent V/pA - MCTG_UNITS_VOLTS_PER_PICOAMP\n
    *    @indent None - MCTG_UNITS_NONE\n
    */
   unsigned int uRawScaleFactorUnits;
   /**
    * @brief Hardware type identifier.
    *
    * Values:\n
    *  @indent MCTG_HW_TYPE_MC700A\n
    *  @indent MCTG_HW_TYPE_MC700B\n
    */
   unsigned int uHardwareType;
   ///@brief Gain of raw (secondary) output.
   double dSecondaryAlpha;
   ///@brief Lowpass filter cutoff frequency [Hz] of raw (secondary) output.
   double dSecondaryLPFCutoff;
   ///@brief Application version of MultiClamp Commander 2.x.
   char* szAppVersion;
   ///@brief Firmware version of MultiClamp 700B.
   char* szFirmwareVersion;
   ///@brief DSP version of MultiClamp 700B.
   char* szDSPVersion;
   ///@brief Serial number of MultiClamp 700B.
   char* szSerialNumber;
   ///@brief The last time this structure has been updated, in system ticks.
   LARGE_INTEGER refreshTickCount;
} MCT_state;

static const char* MCT_SCALE_UNITS[] = {"V/V", "V/mV", "V/uV", "V/A", "V/mA", "V/uA", "V/nA", "V/pA", "None"};


/*********************************
 *       GLOBAL VARIABLES        *
 *********************************/

///@brief Flag to indicate if initialization has been performed.
BOOL MCT_initialized = 0;

///@brief Handle to the window used to recieve messages.
HWND MCT_hwnd = NULL;

///@brief The class used when creating the message processing client window.
WNDCLASSEX MCT_wndClass;

//@brief Handle to the thread used to process window messages.
HANDLE MCT_messageProcessingThread = NULL;

///@brief Boolean flag that is true when the message processing thread is running.
BOOL MCT_messageThreadRunning = FALSE;

///@brief Boolean flag that is true when an outstanding request to shut down the message processing thread exists.
BOOL MCT_messageThreadShutdown = FALSE;

/**
 * @brief The Windows thread ID for the message processing thread.
 * This is not strictly necessary, and is only kept for good bookkeeping.
 */
DWORD MCT_messagePumpThreadID = 0;

///@brief Only one thread may be accessing the global state array at one time, this is used to synchronize access across threads.
CRITICAL_SECTION* MCT_criticalSection;

/**
 * @brief The inverse of the system ticks per second.
 *
 * This is not <tt>performanceFrequency</tt>, which might seem more
 * natural, because such a variable would then be used as the denominator
 * to convert ticks into seconds. Since multiplication is faster than division
 * we cache the division up front.
 */
double MCT_performancePeriod;

///@brief The ID of the MCTG Open message.
DWORD MCT_MCTGOpenMessage;
///@brief The ID of the MCTG Close message.
DWORD MCT_MCTGCloseMessage;
///@brief The ID of the MCTG Request message.
DWORD MCT_MCTGRequestMessage;
///@brief The ID of the MCTG Reconnect message.
DWORD MCT_MCTGReconnectMessage;
///@brief The ID of the MCTG Broadcast message.
DWORD MCT_MCTGBroadcastMessage;
///@brief The ID of the MCTG ID message.
DWORD MCT_MCTGIDMessage;
///@brief The ID of the MCT Shutdown message.
DWORD MCT_SHUTDOWN;

///@brief An array of MCT_state objects, one for each amplifier/channel.
MCT_state** MCT_amplifiers;
///@brief The length of the <tt>MCT_amplifiers</tt> array.
int MCT_amplifiersLength;

/*********************************
 *      UTILITY FUNCTIONS        *
 *********************************/

/**
 * @brief Copies a string to a newly allocated block of memory.
 *
 * The calling function assumes responsibility for freeing the newly allocated memory.
 * @arg <tt>src</tt> - The string to be copied.
 * @return The newly allocated copy of the string, the caller is responsible for freeing this memory.
 */
char* MCT_copyString(const char* src)
{
   char* dest;
   int sz;

   sz = strlen(src) + 1;
   dest = (char *)calloc(sz, sizeof(char));
   memcpy(dest, src, sz);

   return dest;
}

/**
 * @brief Converts "ticks" into current age in seconds.
 *
 * This function is declared as inline because it is quite small and trivial... and built for speed, baby, yeah!
 * Of course, this will be called relatively infrequently, so speed really doesn't matter, I'm just keeping myself amused.
 * @arg <tt>ticks</tt> - The number of system ticks, as retrieved via Windows' QueryPerformanceCounter function.
 * @return The number of seconds that corresponds to <tt>ticks</tt>.
 * @see QueryPerformanceCounter
 * @see performancePeriod
 */
inline double MCT_ticksToSeconds(LARGE_INTEGER ticks)
{
   LARGE_INTEGER currentTicks;

   QueryPerformanceCounter(&currentTicks);

   MCT_debugMsg("Computing seconds:\n\tcurrentTicks = %lld\n\tticks = %lld\n\tseconds per tick = %3.4f\n\telapsed time = %3.5f [s]\n",
      currentTicks.QuadPart, ticks.QuadPart, MCT_performancePeriod, (double)(currentTicks.QuadPart - ticks.QuadPart) * MCT_performancePeriod);

   return (currentTicks.QuadPart - ticks.QuadPart) * MCT_performancePeriod;
}

/**
 * @brief Prints the Windows error message corresponding to <tt>GetLastError()</tt>.
 * @see http://msdn.microsoft.com/en-us/library/ms679351(VS.85).aspx
 */
void printWindowsErrorMessage(void)
{
   DWORD lastError;
   LPTSTR errorMsg = NULL;

   lastError = GetLastError();
   //FormatMessage(dwFlags, lpSource, dwMessageId, dwLanguageId, lpBuffer, nSize, Arguments)
   if (!FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS, NULL, lastError, NULL, (LPTSTR)&errorMsg, 1024, NULL))
   {
      MCT_printMsg("printWindowsErrorMessage() - Failed to format message for error: %d\n"
                   "                             FormatMessage Error: %d\n", lastError, GetLastError());
      return;
   }

   MCT_errorMsg("Windows Error: %d\n"
                "                          %s\n", lastError, errorMsg);
   LocalFree(errorMsg);

   return;
}


/*********************************
 *       MCT_state METHODS       *
 *********************************/

/**
 * @brief Constructor for a MCT_state object.
 *
 * @return A new, uninitialized MCT_state structure.
 */
MCT_state* MCT_stateCreate(void)
{
    MCT_state* state;

    MCT_debugMsg("Creating new MCT_state object.\n");
    state = (MCT_state *)calloc(1, sizeof(MCT_state));
    state->szAppVersion = (char *)calloc(16, sizeof(char));
    state->szFirmwareVersion = (char *)calloc(16, sizeof(char));
    state->szDSPVersion = (char *)calloc(16, sizeof(char));
    state->szSerialNumber = (char *)calloc(16, sizeof(char));

    return state;
}

/**
 * @brief Destructor for a MCT_state object.
 *
 * The pointer itself is destroyed, which is why this requires an extra level of
 * indirection (it wants the reference to the MCT_state pointer. This prevents
 * potential abuse and memory corruption.
 *
 * @arg <tt>state</tt> - The reference to the pointer for a valid MCT_state structure.
 *
 * @pre <tt>state</tt> is a valid MCT_state structure.
 * @post <tt>state</tt> is NULL and all associated memory is free.
 */
void MCT_stateDestroy(MCT_state** state)
{
    MCT_debugMsg("Destroying MCT_state object: @%p\n", *state);
    
    if (*state == NULL)
       return;

    free((*state)->szAppVersion);
    free((*state)->szFirmwareVersion);
    free((*state)->szDSPVersion);
    free((*state)->szSerialNumber);
    free(state);

    *state = NULL;

    return;
}

/**
 * @brief Return a value representing the uScaleFactorUnits as a string
 *
 * @arg <tt>uScaleFactorUnits</tt> - The uScaleFactorUnits that is to be converted into a string.
 * @arg <tt>uHardwareType</tt> - The uHardwareType of the corresponding amplifier.
 * @arg <tt>uOperatingMode</tt> - The uOperatingMode of the corresponding amplifier.
 * @return The resulting string.
 */
const char* MCT_scaleFactorUnitsToString(UINT uScaleFactorUnits, UINT uHardwareType, UINT uOperatingMode, UINT uScaledOutSignal)
{
   if (uHardwareType == MCTG_HW_TYPE_MC700A)
   {
      /*
       * The following values had to be empirically determined, because the values supplied in
       * MultiClampBroadcastMsg.hpp do not, in any way, correspond to the actual signal
       * being sent to the Scaled Output BNC.
       * Here's what they suggest:
       *     const UINT MCTG_OUT_MUX_I_CMD_SUMMED    = 0;
       *     const UINT MCTG_OUT_MUX_V_CMD_SUMMED    = 1;
       *     const UINT MCTG_OUT_MUX_I_CMD_EXT       = 2;
       *     const UINT MCTG_OUT_MUX_V_CMD_EXT       = 3;
       *     const UINT MCTG_OUT_MUX_I_MEMBRANE      = 4;
       *     const UINT MCTG_OUT_MUX_V_MEMBRANE      = 5;
       *     const UINT MCTG_OUT_MUX_V_MEMBRANEx100  = 6;
       *     const UINT MCTG_OUT_MUX_I_AUX1          = 7;
       *     const UINT MCTG_OUT_MUX_V_AUX1          = 8;
       *     const UINT MCTG_OUT_MUX_I_AUX2          = 9;
       *     const UINT MCTG_OUT_MUX_V_AUX2          = 10;
       * Here are the actual values:
       *  Voltage Clamp -
       *     0 = Membrane Potential [10 V/V]            ? MCTG_OUT_MUX_I_CMD_SUMMED
       *     1 = Membrane Current [0.5 V/nA]            ? MCTG_OUT_MUX_V_CMD_SUMMED
       *     2 = Pipette Potential [1 V/V]              ? MCTG_OUT_MUX_I_CMD_EXT
       *     3 = 100 x AC Pipette Potential [0.1 V/mV]  ? MCTG_OUT_MUX_V_CMD_EXT
       *     5 = Bath Potential [N/A]                   ? MCTG_OUT_MUX_V_MEMBRANE
       *  Current Clamp -
       *     0 = Command Current [0.5 V/nA]             ? MCTG_OUT_MUX_I_CMD_SUMMED
       *     1 = Membrane Current [0.5 V/nA]            ? MCTG_OUT_MUX_V_CMD_SUMMED
       *     2 = Membrane Potential [1 V/V]             ? MCTG_OUT_MUX_I_CMD_EXT
       *     3 = 100 x AC Membrane Potential [0.1 V/mV] ? MCTG_OUT_MUX_V_CMD_EXT
       *     5 = Bath Potential [N/A]                   ? MCTG_OUT_MUX_V_MEMBRANE
       */
      if (uOperatingMode == MCTG_MODE_VCLAMP)
      {
         switch (uScaledOutSignal)
         {
            case 0:
               return "V/V";//Membrane Potential [10 V/V]
            case 1:
               return "V/nA";//Membrane Current [0.5 V/nA]
            case 2:
               return "V/V";//Pipette Potential [1 V/V]
            case 3:
               return "V/mV";//100 x AC Pipette Potential [0.1 V/mV]
            case 5:
               return "";//Bath Potential [N/A]
            default:
               return "ERROR - Unknown uScaledOutSignal value";//???
         }
      }
      else if ((uOperatingMode == MCTG_MODE_ICLAMP) || (uOperatingMode == MCTG_MODE_ICLAMPZERO))
      {
         switch (uScaledOutSignal)
         {
            case 0:
               return "V/nA";//Command Current [0.5 V/nA]
            case 1:
               return "V/nA";//Membrane Current [0.5 V/nA]
            case 2:
               return "V/V";//Membrane Potential [1 V/V]
            case 3:
               return "V/mV";//100 x AC Membrane Potential [0.1 V/mV]
            case 5:
               return "";//Bath Potential [N/A]
            default:
               return "ERROR - Unknown uScaledOutSignal value";//???
         }
      }
   }
   else if (uHardwareType == MCTG_HW_TYPE_MC700B)
      return MCT_SCALE_UNITS[uScaleFactorUnits];
   else
      return "UNKNOWN_SCALE_UNITS";
      
   return "This code is unreachable, dumb compiler.";
}

/**
 * @brief Return a value representing the uScaleFactorUnits as a string
 *
 * @arg <tt>state</tt> - The state whose uScaleFactorUnits is to be converted into a string.
 * @return The resulting string.
 */
const char* MCT_getScaleFactorUnitsString(MCT_state* state)
{
   return MCT_scaleFactorUnitsToString(state->uScaleFactorUnits, state->uHardwareType, state->uOperatingMode, state->uScaledOutSignal);
}

/**
 * @brief Return a value representing the uScaledOutSignal as a long string
 *
 * @arg <tt>uScaledOutSignal</tt> - The uScaledOutSignal that is to be converted into a string.
 * @arg <tt>uHardwareType</tt> - The uHardwareType of the corresponding amplifier.
 * @arg <tt>uOperatingMode</tt> - The uOperatingMode of the corresponding amplifier.
 * @return The resulting string.
 */
const char* MCT_scaledOutSignalToLongName(UINT uScaledOutSignal, UINT uHardwareType, UINT uOperatingMode)
{
   if (uHardwareType == MCTG_HW_TYPE_MC700A)
   {
      /*
       * The following values had to be empirically determined, because the values supplied in
       * MultiClampBroadcastMsg.hpp do not, in any way, correspond to the actual signal
       * being sent to the Scaled Output BNC.
       * Here's what they suggest:
       *     const UINT MCTG_OUT_MUX_I_CMD_SUMMED    = 0;
       *     const UINT MCTG_OUT_MUX_V_CMD_SUMMED    = 1;
       *     const UINT MCTG_OUT_MUX_I_CMD_EXT       = 2;
       *     const UINT MCTG_OUT_MUX_V_CMD_EXT       = 3;
       *     const UINT MCTG_OUT_MUX_I_MEMBRANE      = 4;
       *     const UINT MCTG_OUT_MUX_V_MEMBRANE      = 5;
       *     const UINT MCTG_OUT_MUX_V_MEMBRANEx100  = 6;
       *     const UINT MCTG_OUT_MUX_I_AUX1          = 7;
       *     const UINT MCTG_OUT_MUX_V_AUX1          = 8;
       *     const UINT MCTG_OUT_MUX_I_AUX2          = 9;
       *     const UINT MCTG_OUT_MUX_V_AUX2          = 10;
       * Here are the actual values:
       *  Voltage Clamp -
       *     0 = Membrane Potential [10 V/V]            ? MCTG_OUT_MUX_I_CMD_SUMMED
       *     1 = Membrane Current [0.5 V/nA]            ? MCTG_OUT_MUX_V_CMD_SUMMED
       *     2 = Pipette Potential [1 V/V]              ? MCTG_OUT_MUX_I_CMD_EXT
       *     3 = 100 x AC Pipette Potential [0.1 V/mV]  ? MCTG_OUT_MUX_V_CMD_EXT
       *     5 = Bath Potential [N/A]                   ? MCTG_OUT_MUX_V_MEMBRANE
       *  Current Clamp -
       *     0 = Command Current [0.5 V/nA]             ? MCTG_OUT_MUX_I_CMD_SUMMED
       *     1 = Membrane Current [0.5 V/nA]            ? MCTG_OUT_MUX_V_CMD_SUMMED
       *     2 = Membrane Potential [1 V/V]             ? MCTG_OUT_MUX_I_CMD_EXT
       *     3 = 100 x AC Membrane Potential [0.1 V/mV] ? MCTG_OUT_MUX_V_CMD_EXT
       *     5 = Bath Potential [N/A]                   ? MCTG_OUT_MUX_V_MEMBRANE
       */
      if (uOperatingMode == MCTG_MODE_VCLAMP)
      {
         switch (uScaledOutSignal)
         {
            case 0:
               return "Membrane Potential";//Membrane Potential [10 V/V]
            case 1:
               return "Membrane Current";//Membrane Current [0.5 V/nA]
            case 2:
               return "Pipette Potential";//Pipette Potential [1 V/V] 
            case 3:
               return "100 x AC Pipette Potential";//100 x AC Pipette Potential [0.1 V/mV]
            case 5:
               return "Bath Potential";//Bath Potential [N/A]
            default:
               return "ERROR - Unknown uScaledOutSignal value";//???
         }
      }
      else if ((uOperatingMode == MCTG_MODE_ICLAMP) || (uOperatingMode == MCTG_MODE_ICLAMPZERO))
      {
         switch (uScaledOutSignal)
         {
            case 0:
               return "Command Current";//Command Current [0.5 V/nA]
            case 1:
               return "Membrane Current";//Membrane Current [0.5 V/nA]
            case 2:
               return "Membrane Potential";//Membrane Potential [1 V/V] 
            case 3:
               return "100 x AC Membrane Potential";//100 x AC Membrane Potential [0.1 V/mV]
            case 5:
               return "Bath Potential";//Bath Potential [N/A]
            default:
               return "ERROR - Unknown uScaledOutSignal value";//???
         }
      }
   }
   else if (uHardwareType == MCTG_HW_TYPE_MC700B)
      return MCTG_OUT_GLDR_LONG_NAMES[uScaledOutSignal];
   else
      return "ERROR - Unknown uHardwareType value";//???
   
   return "How did we ever get to this line of code?";
}

/**
 * @brief Return a value representing the uScaledOutSignal as a short string
 *
 * @arg <tt>uScaledOutSignal</tt> - The uScaledOutSignal that is to be converted into a string.
 * @arg <tt>uHardwareType</tt> - The uHardwareType of the corresponding amplifier.
 * @arg <tt>uOperatingMode</tt> - The uOperatingMode of the corresponding amplifier.
 * @return The resulting string.
 */
const char* MCT_scaledOutSignalToShortName(UINT uScaledOutSignal, UINT uHardwareType, UINT uOperatingMode)
{
   if (uHardwareType == MCTG_HW_TYPE_MC700A)
   {
      /*
       * The following values had to be empirically determined, because the values supplied in
       * MultiClampBroadcastMsg.hpp do not, in any way, correspond to the actual signal
       * being sent to the Scaled Output BNC.
       * Here's what they suggest:
       *     const UINT MCTG_OUT_MUX_I_CMD_SUMMED    = 0;
       *     const UINT MCTG_OUT_MUX_V_CMD_SUMMED    = 1;
       *     const UINT MCTG_OUT_MUX_I_CMD_EXT       = 2;
       *     const UINT MCTG_OUT_MUX_V_CMD_EXT       = 3;
       *     const UINT MCTG_OUT_MUX_I_MEMBRANE      = 4;
       *     const UINT MCTG_OUT_MUX_V_MEMBRANE      = 5;
       *     const UINT MCTG_OUT_MUX_V_MEMBRANEx100  = 6;
       *     const UINT MCTG_OUT_MUX_I_AUX1          = 7;
       *     const UINT MCTG_OUT_MUX_V_AUX1          = 8;
       *     const UINT MCTG_OUT_MUX_I_AUX2          = 9;
       *     const UINT MCTG_OUT_MUX_V_AUX2          = 10;
       * Here are the actual values:
       *  Voltage Clamp -
       *     0 = Membrane Potential [10 V/V]            ? MCTG_OUT_MUX_I_CMD_SUMMED
       *     1 = Membrane Current [0.5 V/nA]            ? MCTG_OUT_MUX_V_CMD_SUMMED
       *     2 = Pipette Potential [1 V/V]              ? MCTG_OUT_MUX_I_CMD_EXT
       *     3 = 100 x AC Pipette Potential [0.1 V/mV]  ? MCTG_OUT_MUX_V_CMD_EXT
       *     5 = Bath Potential [N/A]                   ? MCTG_OUT_MUX_V_MEMBRANE
       *  Current Clamp -
       *     0 = Command Current [0.5 V/nA]             ? MCTG_OUT_MUX_I_CMD_SUMMED
       *     1 = Membrane Current [0.5 V/nA]            ? MCTG_OUT_MUX_V_CMD_SUMMED
       *     2 = Membrane Potential [1 V/V]             ? MCTG_OUT_MUX_I_CMD_EXT
       *     3 = 100 x AC Membrane Potential [0.1 V/mV] ? MCTG_OUT_MUX_V_CMD_EXT
       *     5 = Bath Potential [N/A]                   ? MCTG_OUT_MUX_V_MEMBRANE
       */
      if (uOperatingMode == MCTG_MODE_VCLAMP)
      {
         switch (uScaledOutSignal)
         {
            case 0:
               return "Vm";//Membrane Potential [10 V/V]
            case 1:
               return "Im";//Membrane Current [0.5 V/nA]
            case 2:
               return "Vp";//Pipette Potential [1 V/V]
            case 3:
               return "100Vp";//100 x AC Pipette Potential [0.1 V/mV]
            case 5:
               return "Vb";//Bath Potential [N/A]
            default:
               return "ERROR - Unknown uScaledOutSignal value";//???
         }
      }
      else if ((uOperatingMode == MCTG_MODE_ICLAMP) || (uOperatingMode == MCTG_MODE_ICLAMPZERO))
      {
         switch (uScaledOutSignal)
         {
            case 0:
               return "Vext";//Command Current [0.5 V/nA]
            case 1:
               return "Im";//Membrane Current [0.5 V/nA]
            case 2:
               return "Vm";//Membrane Potential [1 V/V]
            case 3:
               return "100Vm";//100 x AC Membrane Potential [0.1 V/mV]
            case 5:
               return "Vb";//Bath Potential [N/A]
            default:
               return "ERROR - Unknown uScaledOutSignal value";//???
         }
      }
   }
   else if (uHardwareType == MCTG_HW_TYPE_MC700B)
      return MCTG_OUT_GLDR_SHORT_NAMES[uScaledOutSignal];
   else
      return "ERROR - Unknown uHardwareType value";//???

   return "How did we ever get to this line of code?";
}

/**
 * @brief Return a value representing the uScaledOutSignal as a long string
 *        Calls through to MCT_scaledOutSignalToLongName.
 *
 * @arg <tt>state</tt> - The state whose uScaledOutSignal is to be converted into a string.
 * @return The resulting string.
 */
const char* MCT_getScaledOutSignalLongName(MCT_state* state)
{
   return MCT_scaledOutSignalToLongName(state->uScaledOutSignal, state->uHardwareType, state->uOperatingMode);
}

/**
 * @brief Return a value representing the uScaledOutSignal as a short string
 *        Calls through to MCT_scaledOutSignalToShortName.
 *
 * @arg <tt>state</tt> - The state whose uScaledOutSignal is to be converted into a string.
 * @return The resulting string.
 */
const char* MCT_getScaledOutSignalShortName(MCT_state* state)
{
   return MCT_scaledOutSignalToShortName(state->uScaledOutSignal, state->uHardwareType, state->uOperatingMode);
}

/**
 * @brief Render the MCT_state struct as a string.
 * @arg <tt>state</tt> - The state to be converted into a string.
 * @arg <tt>str</tt> - The character array in which to render the string.
 */
int MCT_stateToString(MCT_state* state, char* str, size_t strSize)
{
   unsigned int uComPortID, uAxoBusID, uChannelID, uSerialNum;
   MCT_debugMsg("MCT_stateToString(@%p)\n", state);

   if (state == NULL)
      return sprintf_s(str, strSize, "MCT_state: NULL\n");

   if (state->uHardwareType == MCTG_HW_TYPE_MC700A)
   {
      MCTG_Unpack700ASignalIDs(state->ID, &uComPortID, &uAxoBusID, &uChannelID);
      uSerialNum = 0;
   }
   else if (state->uHardwareType == MCTG_HW_TYPE_MC700B)
   {
      MCTG_Unpack700BSignalIDs(state->ID, &uSerialNum, &uChannelID);
      uComPortID = 0;
      uAxoBusID = 0;
   }

   return sprintf_s(str, strSize,
                    "MCT_state:\n"
                    "\tID:                     0x%p (%u)\n"
                    "\tOperating Mode:         %s\n"
                    "\tScaled Out Signal:      %s (%s)\n"
                    "\tAlpha:                  %3.4f\n"
                    "\tScaleFactor:            %3.4f\n"
                    "\tScaleFactorUnits:       %s\n"
                    "\tLPF Cutoff:             %3.4f\n"
                    "\tMembrane Capacitance:   %3.4f\n"
                    "\tExt Cmd Sense:          %3.4f\n"
                    "\tRaw Out Signal:         %s (%s)\n"
                    "\tRaw Scale Factor:       %3.4f\n"
                    "\tRaw Scale Factor Units: %s\n"
                    "\tHardware Type:          %s\n"
                    "\tSecondary Alpha:        %3.4f\n"
                    "\tSecondary LPF Cutoff:   %3.4f\n"
                    "\tApp Version:            %s\n"
                    "\tFirmware Version:       %s\n"
                    "\tDSPVersion:             %s\n"
                    "\tSerial Number:          %s\n"
                    "\tuComPortID:             %u\n"
                    "\tuAxoBusID:              %u\n"
                    "\tuChannelID:             %u\n"
                    "\tuSerialNum:             %u\n"
                    "\trefreshTickCount:       %llu (Elapsed time = %3.4f [s])\n",
                    state->ID, state->ID,
                    MCTG_MODE_NAMES[state->uOperatingMode],
                    MCT_getScaledOutSignalLongName(state),
                    MCT_getScaledOutSignalShortName(state),
                    state->dAlpha,
                    state->dScaleFactor,
                    MCT_getScaleFactorUnitsString(state),
                    state->dLPFCutoff,
                    state->dMembraneCap,
                    state->dExtCmdSens,
                    "NOT_YET_IMPLEMENTED",
                    "NOT_YET_IMPLEMENTED",
                    state->dRawScaleFactor,
                    "NOT_YET_IMPLEMENTED",
                    MCTG_HW_TYPE_NAMES[state->uHardwareType],
                    state->dSecondaryAlpha,
                    state->dSecondaryLPFCutoff,
                    state->szAppVersion,
                    state->szFirmwareVersion,
                    state->szDSPVersion,
                    state->szSerialNumber,
                    uComPortID,
                    uAxoBusID,
                    uChannelID,
                    uSerialNum,
                    state->refreshTickCount.QuadPart,
                    MCT_ticksToSeconds(state->refreshTickCount));
}

/**
 * @brief Display the state to the console.
 * @arg <tt>state</tt> - The state to be displayed.
 */
void MCT_displayState(MCT_state* state)
{
   char str[1024];

   MCT_debugMsg("MCT_displayState(@%p)\n", state);

   MCT_stateToString(state, str, 1024);
   MCT_printMsg("%s", str);

   return;
}

/*********************************
 *       DISPLAY FUNCTIONS       *
 *********************************/

/**
 * @brief Display the state of all the <tt>MCT_amplifiers</tt> to the console.
 */
void MCT_displayAmplifiers(void)
{
   int i;

   for (i = 0; i < MCT_amplifiersLength; i++)
      MCT_displayState(MCT_amplifiers[i]);

   return;
}

/**
 * @brief Render the MC_TELEGRAPH_DATA struct as a string.
 * @arg <tt>state</tt> - The packet to be converted into a string.
 * @arg <tt>str</tt> - The character array in which to render the string.
 */
int MCT_MCTGPacketToString(MC_TELEGRAPH_DATA* mctgPacket, char* str, size_t strSize)
{
   LPARAM ID = 0;
   MCT_debugMsg("MCT_MCTGPacketToString(@%p)\n", mctgPacket);

   if (mctgPacket == NULL)
      return sprintf_s(str, strSize, "MCT_state: NULL\n");

   if (mctgPacket->uHardwareType == MCTG_HW_TYPE_MC700A)
   {
      MCT_debugMsg("MCT_MCTGPacketToString: @%p is from a 700A.\n", mctgPacket);
      ID = MCTG_Pack700ASignalIDs(mctgPacket->uComPortID, mctgPacket->uAxoBusID, mctgPacket->uChannelID);
   }
   else if (mctgPacket->uHardwareType == MCTG_HW_TYPE_MC700B)
   {
      MCT_debugMsg("MCT_MCTGPacketToString: @%p is from a 700B.\n", mctgPacket);
      ID = MCTG_Pack700BSignalIDs(strtoul(mctgPacket->szSerialNumber, NULL, 10), mctgPacket->uChannelID);
   }

   if (mctgPacket->uHardwareType == MCTG_HW_TYPE_MC700A)
      return sprintf_s(str, strSize,
                       "MC_TELEGRAPH_DATA (0x%p):\n"
                       "\tID:                     0x%p (%u)\n"
                       "\tOperating Mode:         %s\n"
                       "\tScaled Out Signal:      %s (%s)\n"
                       "\tAlpha:                  %3.4f\n"
                       "\tScaleFactor:            %3.4f\n"
                       "\tScaleFactorUnits:       %s\n"
                       "\tLPF Cutoff:             %3.4f\n"
                       "\tMembrane Capacitance:   %3.4f\n"
                       "\tExt Cmd Sense:          %3.4f\n"
                       "\tRaw Out Signal:         %s (%s)\n"
                       "\tRaw Scale Factor:       %3.4f\n"
                       "\tRaw Scale Factor Units: %s\n"
                       "\tHardware Type:          %s\n"
                       "\tSecondary Alpha:        %3.4f\n"
                       "\tSecondary LPF Cutoff:   %3.4f\n"
                       "\tuComPortID:             %u\n"
                       "\tuAxoBusID:              %u\n"
                       "\tuChannelID:             %u\n"
                       "\tuVersion:               %u\n",
                       mctgPacket,
                       ID, ID,
                       MCTG_MODE_NAMES[mctgPacket->uOperatingMode],
                       MCT_scaledOutSignalToLongName(mctgPacket->uScaledOutSignal, mctgPacket->uHardwareType, mctgPacket->uOperatingMode),
                       MCT_scaledOutSignalToShortName(mctgPacket->uScaledOutSignal, mctgPacket->uHardwareType, mctgPacket->uOperatingMode),
                       mctgPacket->dAlpha,
                       mctgPacket->dScaleFactor,
                       MCT_scaleFactorUnitsToString(mctgPacket->uScaleFactorUnits, mctgPacket->uHardwareType, mctgPacket->uOperatingMode, mctgPacket->uScaledOutSignal),
                       mctgPacket->dLPFCutoff,
                       mctgPacket->dMembraneCap,
                       mctgPacket->dExtCmdSens,
                       "NOT_YET_IMPLEMENTED",
                       "NOT_YET_IMPLEMENTED",
                       mctgPacket->dRawScaleFactor,
                       "NOT_YET_IMPLEMENTED",
                       MCTG_HW_TYPE_NAMES[mctgPacket->uHardwareType],
                       mctgPacket->dSecondaryAlpha,
                       mctgPacket->dSecondaryLPFCutoff,
                       mctgPacket->uComPortID,
                       mctgPacket->uAxoBusID,
                       mctgPacket->uChannelID,
                       mctgPacket->uVersion);
   else if (mctgPacket->uHardwareType == MCTG_HW_TYPE_MC700B)
      return sprintf_s(str, strSize,
                       "MC_TELEGRAPH_DATA (0x%p):\n"
                       "\tID:                     0x%p (%u)\n"
                       "\tOperating Mode:         %s\n"
                       "\tScaled Out Signal:      %s (%s)\n"
                       "\tAlpha:                  %3.4f\n"
                       "\tScaleFactor:            %3.4f\n"
                       "\tScaleFactorUnits:       %s\n"
                       "\tLPF Cutoff:             %3.4f\n"
                       "\tMembrane Capacitance:   %3.4f\n"
                       "\tExt Cmd Sense:          %3.4f\n"
                       "\tRaw Out Signal:         %s (%s)\n"
                       "\tRaw Scale Factor:       %3.4f\n"
                       "\tRaw Scale Factor Units: %s\n"
                       "\tHardware Type:          %s\n"
                       "\tSecondary Alpha:        %3.4f\n"
                       "\tSecondary LPF Cutoff:   %3.4f\n"
                       "\tApp Version:            %s\n"
                       "\tFirmware Version:       %s\n"
                       "\tDSPVersion:             %s\n"
                       "\tSerial Number:          %s\n"
                       "\tuComPortID:             %u\n"
                       "\tuAxoBusID:              %u\n"
                       "\tuChannelID:             %u\n"
                       "\tuVersion:               %u\n",
                       mctgPacket,
                       ID, ID,
                       MCTG_MODE_NAMES[mctgPacket->uOperatingMode],
                       MCT_scaledOutSignalToLongName(mctgPacket->uScaledOutSignal, mctgPacket->uHardwareType, mctgPacket->uOperatingMode),
                       MCT_scaledOutSignalToShortName(mctgPacket->uScaledOutSignal, mctgPacket->uHardwareType, mctgPacket->uOperatingMode),
                       mctgPacket->dAlpha,
                       mctgPacket->dScaleFactor,
                       MCT_scaleFactorUnitsToString(mctgPacket->uScaleFactorUnits, mctgPacket->uHardwareType, mctgPacket->uOperatingMode, mctgPacket->uScaledOutSignal),
                       mctgPacket->dLPFCutoff,
                       mctgPacket->dMembraneCap,
                       mctgPacket->dExtCmdSens,
                       "NOT_YET_IMPLEMENTED",
                       "NOT_YET_IMPLEMENTED",
                       mctgPacket->dRawScaleFactor,
                       "NOT_YET_IMPLEMENTED",
                       MCTG_HW_TYPE_NAMES[mctgPacket->uHardwareType],
                       mctgPacket->dSecondaryAlpha,
                       mctgPacket->dSecondaryLPFCutoff,
                       mctgPacket->szAppVersion,
                       mctgPacket->szFirmwareVersion,
                       mctgPacket->szDSPVersion,
                       mctgPacket->szSerialNumber,
                       mctgPacket->uComPortID,
                       mctgPacket->uAxoBusID,
                       mctgPacket->uChannelID,
                       mctgPacket->uVersion);
   else
      return sprintf_s(str, strSize, "Unrecognized uHardwareType: %u\n", mctgPacket->uHardwareType);
}

/*********************************
 *    AMPLIFIER ARRAY METHODS    *
 *********************************/

/**
 * @brief Resizes the amplifier array, moving all structures into the new array.
 *        If <tt>newSize</tt> is equal to or smaller than the current size, nothing is done.
 *
 * @arg <tt>newSize</tt> - The desired array size.
 */
void MCT_resizeAmplifiersArray(unsigned int newSize)
{
   MCT_state** temp;
   int i;

   MCT_debugMsg("MCT_resizeAmplifiersArray(%u), MCT_amplifiersLength = %u\n", newSize, MCT_amplifiersLength);

   if (newSize <= MCT_amplifiersLength)
      return;

   temp = (MCT_state **)calloc(newSize, sizeof(MCT_state));

   MCT_debugMsg("MCT_resizeAmplifiersArray() - Entering critical section...\n");
   EnterCriticalSection(MCT_criticalSection);

   if (MCT_amplifiers != NULL)
   {   
      for (i = 0; i < MCT_amplifiersLength; i++)
         temp[i] = MCT_amplifiers[i];

      free(MCT_amplifiers);
   }

   MCT_amplifiers = temp;
   MCT_amplifiersLength = newSize;

   #ifdef MCT_DEBUG
      MCT_debugMsg("MCT_amplifiers:\n");
      for (i = 0; i < MCT_amplifiersLength; i++)
      {
         MCT_printMsg("MCT_amplifiers[%d] = @%p\n", i, MCT_amplifiers[i]);
         MCT_displayState(MCT_amplifiers[i]);
      }
   #endif

   MCT_debugMsg("MCT_resizeAmplifiersArray() - Leaving critical section...\n");
   LeaveCriticalSection(MCT_criticalSection);

   return;
}


/**
 * @brief Look up an MCT_state struct's index by its ID.
 * @arg <tt>ID</tt> - The ID of the struct to be found.
 * @return The index of the struct, -1 if not found and there is space in the array, -2 if not found and the array is full.
 */
int MCT_getAmplifierIndex(LPARAM ID)
{
   int i = -1;
   int isSpace = 0;

   MCT_debugMsg("MCT_getAmplifierIndex(0x%p)\n", ID);

   MCT_debugMsg("MCT_getAmplifierIndex() - Entering critical section...\n");
   EnterCriticalSection(MCT_criticalSection);

   for (i = 0; i < MCT_amplifiersLength; i++)
   {
      if (MCT_amplifiers[i] != NULL)
      {
         if (MCT_amplifiers[i]->ID == ID)
         {
           MCT_debugMsg("MCT_getAmplifierIndex() - Leaving critical section...\n");
           LeaveCriticalSection(MCT_criticalSection);
           MCT_debugMsg("MCT_getAmplifierIndex(0x%p) = %d\n", ID, i);
           return i;
         }
      }
      else
         isSpace = 1;
   }

   MCT_debugMsg("MCT_getAmplifierIndex() - Leaving critical section...\n");
   LeaveCriticalSection(MCT_criticalSection);

   MCT_debugMsg("MCT_getAmplifierIndex(%p), NOT_FOUND, isSpace = %d\n", ID, isSpace);
   if (isSpace)
      return -1;
   else
      return -2;
}

/**
 * @brief Look up an MCT_state struct's index by its ID.
 * @arg <tt>ID</tt> - The ID of the struct to be found.
 * @return The index of the struct, or the index of a new/empty slot in which to store a struct.
 */
int MCT_getOrCreateAmplifierIndex(LPARAM ID)
{
   int i;

   MCT_debugMsg("MCT_getOrCreateAmplifierIndex(%p)\n", ID);

   MCT_debugMsg("MCT_getOrCreateAmplifierIndex() - Entering critical section...\n");
   EnterCriticalSection(MCT_criticalSection);

   i = MCT_getAmplifierIndex(ID);

   if (i == -1)
   {
      //Find the empty space and create a new entry there.
      for (i = 0; i < MCT_amplifiersLength; i++)
      {
         if (MCT_amplifiers[i] == NULL)
         {
            MCT_debugMsg("MCT_getOrCreateAmplifierIndex(%p) - creating new struct at index %d\n", ID, i);
            MCT_amplifiers[i] = MCT_stateCreate();
            break;
         }
      }
   }
   else if (i == -2)
   {
     MCT_debugMsg("MCT_getOrCreateAmplifierIndex(%p) - Resizing array...\n", ID);
     //Extend the list and create a new entry.
     MCT_resizeAmplifiersArray(MCT_amplifiersLength + 2);
     
     MCT_debugMsg("MCT_getOrCreateAmplifierIndex(%p) - creating new struct at index %d\n", ID, MCT_amplifiersLength);
     MCT_amplifiers[MCT_amplifiersLength] = MCT_stateCreate();
   }

   MCT_debugMsg("MCT_getOrCreateAmplifierIndex() - Leaving critical section...\n");
   LeaveCriticalSection(MCT_criticalSection);

   return i;
}

/**
 * @brief Store an MCTG packet into the (global) <tt>MCT_amplifiers</tt> array.
 * @arg <tt>mctgPacket</tt> - A packet recieved from the Multiclamp Commander software, via Windows messaging.
 */
void MCT_storeMCTGPacket(MC_TELEGRAPH_DATA* mctgPacket)
{
   int index;
   LPARAM ID = 0;

   MCT_debugMsg("MCT_storeMCTGPacket(@%p)", mctgPacket);

   if (mctgPacket->uHardwareType == MCTG_HW_TYPE_MC700A)
   {
      MCT_debugMsg("MCT_storeMCTGPacket: @%p is from a 700A.\n", mctgPacket);
      ID = MCTG_Pack700ASignalIDs(mctgPacket->uComPortID, mctgPacket->uAxoBusID, mctgPacket->uChannelID);
   }
   else if (mctgPacket->uHardwareType == MCTG_HW_TYPE_MC700B)
   {
      MCT_debugMsg("MCT_storeMCTGPacket: @%p is from a 700B.\n", mctgPacket);
      ID = MCTG_Pack700BSignalIDs(strtoul(mctgPacket->szSerialNumber, NULL, 10), mctgPacket->uChannelID);
   }
   else
      MCT_printMsg("MulticlampTelegraph - Unrecognizable Multiclamp hardware type: %p\n", mctgPacket->uHardwareType);

   MCT_debugMsg("MCT_storeMCTGPacket(%p) - ID = %p\n", mctgPacket, ID);

   MCT_debugMsg("MCT_storeMCTGPacket() - Entering critical section...\n");
   EnterCriticalSection(MCT_criticalSection);

   index = MCT_getOrCreateAmplifierIndex(ID);

   MCT_debugMsg("MCT_storeMCTGPacket(%p) - Copying ID:%p into index:%d\n", mctgPacket, ID, index);

   //Copy the data over to the local structure.
   MCT_amplifiers[index]->ID = ID;
   MCT_amplifiers[index]->uOperatingMode = mctgPacket->uOperatingMode;
   MCT_amplifiers[index]->uScaledOutSignal = mctgPacket->uScaledOutSignal;
   MCT_amplifiers[index]->dAlpha = mctgPacket->dAlpha;
   MCT_amplifiers[index]->dScaleFactor = mctgPacket->dScaleFactor;
   MCT_amplifiers[index]->uScaleFactorUnits = mctgPacket->uScaleFactorUnits;
   MCT_amplifiers[index]->dLPFCutoff = mctgPacket->dLPFCutoff;
   MCT_amplifiers[index]->dMembraneCap = mctgPacket->dMembraneCap;
   MCT_amplifiers[index]->dExtCmdSens = mctgPacket->dExtCmdSens;
   MCT_amplifiers[index]->uRawOutSignal = mctgPacket->uRawOutSignal;
   MCT_amplifiers[index]->dRawScaleFactor = mctgPacket->dRawScaleFactor;
   MCT_amplifiers[index]->uRawScaleFactorUnits = mctgPacket->uRawScaleFactorUnits;
   MCT_amplifiers[index]->uHardwareType = mctgPacket->uHardwareType;
   MCT_amplifiers[index]->dSecondaryAlpha = mctgPacket->dSecondaryAlpha;
   MCT_amplifiers[index]->dSecondaryLPFCutoff = mctgPacket->dSecondaryLPFCutoff;
   if (mctgPacket->uHardwareType == MCTG_HW_TYPE_MC700A)
   {
      MCT_amplifiers[index]->szAppVersion = UNSPECIFIED_FOR_700A;
      MCT_amplifiers[index]->szFirmwareVersion = UNSPECIFIED_FOR_700A;
      MCT_amplifiers[index]->szDSPVersion = UNSPECIFIED_FOR_700A;
      MCT_amplifiers[index]->szSerialNumber = UNSPECIFIED_FOR_700A;
   }
   else
   {
      MCT_amplifiers[index]->szAppVersion = MCT_copyString(mctgPacket->szAppVersion);
      MCT_amplifiers[index]->szFirmwareVersion = MCT_copyString(mctgPacket->szFirmwareVersion);
      MCT_amplifiers[index]->szDSPVersion = MCT_copyString(mctgPacket->szDSPVersion);
      MCT_amplifiers[index]->szSerialNumber = MCT_copyString(mctgPacket->szSerialNumber);
   }

   QueryPerformanceCounter(&(MCT_amplifiers[index]->refreshTickCount));

   MCT_debugMsg("MCT_storeMCTGPacket(%p) - Updated state %p (MCT_amplifiers[%d]).\n", mctgPacket, ID, index);
   #ifdef MCT_DEBUG
      MCT_displayState(MCT_amplifiers[index]);
   #endif

   MCT_debugMsg("MCT_storeMCTGPacket() - Leaving critical section...\n");
   LeaveCriticalSection(MCT_criticalSection);

   return;
}

/*********************************
 *  WINDOWS THREADING/MESSAGING  *
 *********************************/

/**
 * @brief Open a connection to the specified amplifier (subscribe for updates).
 * @arg <tt>ID</tt> - The ID of the amplifier to which to connect.
 */
void MCT_openConnection(LPARAM ID)
{
   MCT_debugMsg("MCT_openConnection(0x%p)\n", ID);
   PostMessage(HWND_BROADCAST, MCT_MCTGOpenMessage, (WPARAM)MCT_hwnd, ID);
}

/**
 * @brief Close a connection to the specified amplifier (unsubscribe for updates).
 * @arg <tt>ID</tt> - The ID of the amplifier from which to disconnect.
 */
void MCT_closeConnection(LPARAM ID)
{
   MCT_debugMsg("MCT_closeConnection(0x%p)\n", ID);
   PostMessage(HWND_BROADCAST, MCT_MCTGOpenMessage, (WPARAM)MCT_hwnd, ID);
}

/**
 * @brief Request a telegraph packet frm the specified amplifier (request a single update).
 * @arg <tt>ID</tt> - The ID of the amplifier from which to request an update.
 */
void MCT_requestTelegraph(LPARAM ID)
{
   MCT_debugMsg("MCT_requestTelegraph(0x%p)\n", ID);
   PostMessage(HWND_BROADCAST, MCT_MCTGRequestMessage, (WPARAM)MCT_hwnd, ID);
   //Yield the CPU to allow the Multiclamp Commander to respond, and the message processing thread to get the telegraph.
   SwitchToThread();
}

/**
 * @brief Broadcast to all amplifiers, requesting them to identify themselves.
  */
void MCT_broadcast(void)
{
   MCT_debugMsg("MCT_broadcast() - Sending MCT_MCTGBroadcastMessage...\n");
   PostMessage(HWND_BROADCAST, MCT_MCTGBroadcastMessage, (WPARAM)MCT_hwnd, NULL);
   //Yield the CPU to allow the Multiclamp Commander(s) to respond, and the message processing thread to get the telegraph.
   SwitchToThread();
}

/**
 * @brief Returns the handle to the active module (DLL or executable), necessary for working with windows.
 *
 * @return The current module's handle.
 */
HINSTANCE MCT_getCurrentModuleHandle(void)
{
    #ifdef MATLAB_MEX_FILE
       return GetModuleHandle("MultiClampTelegraph.mexw64");
    #else
       return GetModuleHandle("MultiClampTelegraph.exe");
    #endif
}

/**
 * @brief Required function for processing Windows messages.
 *
 * This function is necessary for registering a window class, to create a window.
 * Lots of stupid hoops to jump through, considering I'm pumping my own messages.
 *
 * @see http://msdn.microsoft.com/en-us/library/ms633573(VS.85).aspx
 * @return 1 if processing a normal message, 0 if it is a shutdown message.
 */
LRESULT CALLBACK MCT_WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
   MC_TELEGRAPH_DATA* mctgPacket = NULL;
   #ifdef MCT_DEBUG
      char packetStr[2048];
   #endif
   
   MCT_debugMsg("MCT_WindowProc(hwnd: %p, uMsg: %p, wParam: %p, lParam: %p)\n", hwnd, uMsg, wParam, lParam);

   //Process messages.
   if ( (uMsg == MCT_SHUTDOWN) || (uMsg == WM_DESTROY) || (uMsg == WM_QUIT) )
   {
      MCT_debugMsg("MCT_WindowProc(...) - Recieved MCT_SHUTDOWN message.\n");
      return 0;
   }
   else if (uMsg == MCT_MCTGIDMessage)
   {
      MCT_debugMsg("MCT_WindowProc(...) - Recieved MCT_MCTGIDMessage message.\n");
      //MCT_getOrCreateAmplifierIndex(lParam);
      MCT_requestTelegraph(lParam);
      MCT_openConnection(lParam);
   }
   else if (uMsg == MCT_MCTGReconnectMessage)
   {
      MCT_debugMsg("MCT_WindowProc(...) - Recieved MCT_MCTGReconnectMessage message.\n");
      MCT_debugMsg("MCT_WindowProc(...) - Requesting reconnect...\n");
      //MCT_openConnection(lParam);//Request reconnect. Is this necessary?
      MCT_requestTelegraph(lParam);
      //MCT_getOrCreateAmplifierIndex(lParam);
   }
   else if (uMsg == WM_COPYDATA)
   {
      MCT_debugMsg("MCT_WindowProc(...) - Recieved WM_COPYDATA message.\n");
      //Here's a message that's probably from the Multiclamp Commander.
      if (((COPYDATASTRUCT*)lParam)->dwData == MCT_MCTGRequestMessage)
      {
         mctgPacket = (MC_TELEGRAPH_DATA *)((COPYDATASTRUCT*)lParam)->lpData;
         if ((mctgPacket->uVersion != MCTG_API_VERSION_700A) && (mctgPacket->uVersion != MCTG_API_VERSION_700B))
            ;
         //MCT_errorMsg("MultiClampTelegraph Warning - Unrecognized uVersion field found in MC_TELEGRAPH_DATA struct: %u\n", mctgPacket->uVersion);

         #ifdef MCT_DEBUG
            MCT_MCTGPacketToString(mctgPacket, packetStr, 2048);
            MCT_debugMsg("MCT_storeMCTGPacket:\n%s\n", packetStr);
         #endif
         MCT_storeMCTGPacket(mctgPacket);
      }
      else
      {
         MCT_debugMsg("MCT_WindowProc(...) - Recieved unrecognized WM_COPYDATA message: dwData = %p\n", ((COPYDATASTRUCT*)lParam)->dwData);
      }
   }
   else if (uMsg == MCT_MCTGBroadcastMessage)
   {
      if (wParam == (WPARAM)MCT_hwnd)
      {
         MCT_debugMsg("MCT_WindowProc(...) - Recieved MCT_MCTGBroadcastMessage message from %p (MCT_hwnd).\n", wParam);
      }
      else
      {
         MCT_debugMsg("MCT_WindowProc(...) - Recieved MCT_MCTGBroadcastMessage message from %p.\n", wParam);
      }
   }
   else if (uMsg == MCT_MCTGRequestMessage)
   {
      if (wParam == (WPARAM)MCT_hwnd)
      {
         MCT_debugMsg("MCT_WindowProc(...) - Recieved MCT_MCTGRequestMessage message from %p (MCT_hwnd).\n", wParam);
      }
      else
      {
         MCT_debugMsg("MCT_WindowProc(...) - Recieved MCT_MCTGRequestMessage message from %p.\n", wParam);
      }
   }
   else if (uMsg == MCT_MCTGOpenMessage)
   {
      if (wParam == (WPARAM)MCT_hwnd)
      {
         MCT_debugMsg("MCT_WindowProc(...) - Recieved MCT_MCTGOpenMessage message from %p (MCT_hwnd).\n", wParam);
      }
      else
      {
         MCT_debugMsg("MCT_WindowProc(...) - Recieved MCT_MCTGOpenMessage message from %p.\n", wParam);
      }
   }
   else if (uMsg == MCT_MCTGCloseMessage)
   {
      if (wParam == (WPARAM)MCT_hwnd)
      {
         MCT_debugMsg("MCT_WindowProc(...) - Recieved MCT_MCTGCloseMessage message from %p (MCT_hwnd).\n", wParam);
      }
      else
      {
         MCT_debugMsg("MCT_WindowProc(...) - Recieved MCT_MCTGCloseMessage message from %p.\n", wParam);
      }
   }
   else if (uMsg == WM_CREATE)//Sent upon window creation.
   {
        MCT_debugMsg("MCT_WindowProc(...) - Recieved WM_Create message.\n");
   }
   else if (uMsg == WM_GETMINMAXINFO)//Sent upon window creation (depending on the type of window).
   {
        MCT_debugMsg("MCT_WindowProc(...) - Recieved WM_GETMINMAXINFO message.\n");
   }
   else if (uMsg == WM_NCCREATE)//Sent upon window creation (depending on the type of window).
   {
        MCT_debugMsg("MCT_WindowProc(...) - Recieved WM_NCCREATE message.\n");
   }
   else if (uMsg == WM_NCCALCSIZE)//Sent upon window creation (depending on the type of window).
   {
        MCT_debugMsg("MCT_WindowProc(...) - Recieved WM_NCCALCSIZE message.\n");
   }
   else if (uMsg == WM_DESTROY)//Sent upon window destruction.
   {
        MCT_debugMsg("MCT_WindowProc(...) - Recieved WM_DESTROY message.\n");
   }
   else if (uMsg == WM_NCDESTROY)//Sent upon window destruction (depending on the type of window).
   {
        MCT_debugMsg("MCT_WindowProc(...) - Recieved WM_NCDESTROY message.\n");
   }
   else
   {
      //Any other messages should just be ignored, I think. Use them as cues to check for shutdown signals.
      MCT_debugMsg("MCT_WindowProc(...) - Unrecognized window message: %u (See WinUser.h for common window message definitions)\n", uMsg);
   }

   MCT_debugMsg("MCT_WindowProc(...) - Completed message handling.\n");

   return 1;
}

/**
 * @brief Creates the window used to recieve Axon MultiClamp Commander messages.
 */
BOOL MCT_createClientWindow(void)
{
   HINSTANCE moduleHandle = NULL;
   ATOM wndClassAtom = NULL;

   moduleHandle = MCT_getCurrentModuleHandle();
   if (moduleHandle == NULL)
   {
      printWindowsErrorMessage();
      MCT_errorMsg("MCT_createClientWindow() - Failed to get module handle.\n");
      return FALSE;
   }

   if (MCT_hwnd == NULL)
   {
      MCT_wndClass.cbSize = sizeof(WNDCLASSEX);
      MCT_wndClass.style = CS_GLOBALCLASS;
      MCT_wndClass.lpfnWndProc = MCT_WindowProc;
      MCT_wndClass.cbClsExtra = 0;
      MCT_wndClass.cbWndExtra = 0;
      MCT_wndClass.hInstance = moduleHandle;
      MCT_wndClass.hIcon = NULL;
      MCT_wndClass.hCursor = NULL;
      MCT_wndClass.hbrBackground = NULL;
      MCT_wndClass.lpszMenuName = NULL;
      MCT_wndClass.lpszClassName = MCT_WINDOWCLASS_NAME;
      MCT_wndClass.hIconSm = NULL;

      wndClassAtom = RegisterClassEx(&MCT_wndClass);
      if (!wndClassAtom)
      {
         printWindowsErrorMessage();
         MCT_errorMsg("MCT_createClientWindow() - Failed to create register window class.\n");
         return FALSE;
      }

      MCT_debugMsg("MCT_createClientWindow() - Creating window...\n");

      //It's a nice idea to just use a HWND_MESSAGE class of window, but the 700B software sucks and needs to send broadcast messages.
      ////Use a message only window (HWND_MESSAGE), broadcast messages aren't necessary.
      //MCT_hwnd = CreateWindow(MCT_WINDOWCLASS_NAME, "MCT_Message_Only", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
      //                    CW_USEDEFAULT, HWND_MESSAGE, (HMENU)NULL, moduleHandle, (LPVOID)NULL);

      //Use a full-fledged window (WS_OVERLAPPED), so we can recieve our own broadcast messages, for debugging.
      MCT_hwnd = CreateWindow(MCT_WINDOWCLASS_NAME, "MCT_Message_Only", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
                          CW_USEDEFAULT, WS_OVERLAPPED, (HMENU)NULL, moduleHandle, (LPVOID)NULL);
      //#endif
      //#endif
      MCT_debugMsg("MCT_createClientWindow() - Created window: %p\n", MCT_hwnd);
      if (MCT_hwnd == NULL)
      {
         printWindowsErrorMessage();
         MCT_errorMsg("MCT_createClientWindow() - Failed to create messaging client window.\n");
         return FALSE;
      }

      ShowWindow(MCT_hwnd, SW_HIDE);
   }

   MCT_debugMsg("MCT_createClientWindow() - Window has been created.\n");

   return TRUE;
}

/**
 * @brief Tear down the client window used for Windows messaging.
 */
void MCT_destroyClientWindow(void)
{
   HINSTANCE moduleHandle = NULL;
   BOOL result;

   MCT_debugMsg("MCT_destroyClientWindow() - Destroying client window...\n");

   if (!DestroyWindow(MCT_hwnd))
   {
      printWindowsErrorMessage();
      MCT_errorMsg("MCT_destroyClientWindow() - Failed to destroy window.\n");
   }

   moduleHandle = MCT_getCurrentModuleHandle();
   if (moduleHandle == NULL)
   {
      printWindowsErrorMessage();
      MCT_errorMsg("MCT_destroyClientWindow() - Failed to get module handle.\n");
      return;
   }

   if (!UnregisterClass(MCT_WINDOWCLASS_NAME, moduleHandle))
   {
      printWindowsErrorMessage();
      MCT_errorMsg("MCT_destroyClientWindow() - Failed to get unregister window class.\n");
   }

   return;
}

/**
 * @brief Close all connections, for all amplifiers/channels.
 */
void MCT_closeAllConnections(void)
{
  int i;

   MCT_debugMsg("MCT_closeAllConnections() - Entering critical section...\n");
   EnterCriticalSection(MCT_criticalSection);

   for (i = 0; i < MCT_amplifiersLength; i++)
   {
      MCT_debugMsg("MCT_closeAllConnections() - Closing connection for MCT_amplifiers[%d] = @%p...\n", i, MCT_amplifiers[i]);
      if (MCT_amplifiers[i] != NULL)
         MCT_closeConnection(MCT_amplifiers[i]->ID);
   }

   MCT_debugMsg("MCT_closeAllConnections() - Leaving critical section...\n");
   LeaveCriticalSection(MCT_criticalSection);
   MCT_debugMsg("MCT_closeAllConnections() - Completed\n");
}

/**
 * @brief The work function for the message processing thread.
 *
 * @arg <tt>lpParam</tt> - A pointer, as prescribed by the Windows thread creation. Not used.
 * @see http://msdn.microsoft.com/en-us/library/ms644928(VS.85).aspx
 */
DWORD WINAPI MCT_messagePump(LPVOID lpParam)
{
   BOOL gotMessage = 0;
   LPMSG msg = NULL;

   MCT_debugMsg("MCT_messagePump() - Creating client window...\n");

   if (!MCT_createClientWindow())//This thread will own the window.
      return 1;//Window creation failed, no point in continuing.

   MCT_messageThreadRunning = TRUE;

   //Probe for Multiclamp Commanders.
   MCT_debugMsg("MCT_messagePump() - Broadcasting to probe for Multiclamp Commander instances...\n");
   MCT_broadcast();
   MCT_requestTelegraph(MCTG_Pack700ASignalIDs(3, 1, 1));

   MCT_debugMsg("MCT_messagePump() - Starting message pump loop...\n");

   msg = (LPMSG)calloc(1, sizeof(MSG));

   //Wait for messages until we get the shutdown signal.
   //while ( (!MCT_messageThreadShutdown) && (WaitMessage()) )
   while (!MCT_messageThreadShutdown)
   {
     /**The MSDN documentation isn't really clear on whether or not WaitMessage is neccessary, or if GetMessage can
      * be used to block thread execution.
      * Empirical observation suggests that WaitMessage is not necessary.
     MCT_debugMsg("MCT_messagePump() - Waiting for message...\n");
     if (!WaitMessage())
     {
       printWindowsErrorMessage();
        MCT_printMsg("MCT_messagePump() - An error occurred while waiting for a message.\n");
        return 1;
     }*/

     MCT_debugMsg("MCT_messagePump() - Getting message...\n");
     gotMessage = GetMessage(msg, MCT_hwnd, 0, 0);
     if (!gotMessage)
     {
        MCT_debugMsg("MCT_messagePump() - GetMessage(...) returned FALSE!\n");
        continue;//Oops.
     }

     MCT_debugMsg("MCT_messagePump() - Handing message off to MCT_WindowProc(...)...\n");
     if (!MCT_WindowProc(MCT_hwnd, msg->message, msg->wParam, msg->lParam))
     {
        MCT_debugMsg("MCT_messagePump() - Terminating message pump loop...\n");
        break;//Shutdown.
      }
   }

   MCT_debugMsg("MCT_messagePump() - Loop terminated. Closing connections...\n");
   MCT_closeAllConnections();

   MCT_debugMsg("MCT_messagePump() - Loop terminated. Destroying client window...\n");
   MCT_destroyClientWindow();

   //if (!MCT_messageThreadShutdown) //We're shutting down due to an error.

   MCT_messageThreadShutdown = FALSE;
   MCT_messageThreadRunning = FALSE;

   MCT_debugMsg("MCT_messagePump() - Message pump thread terminated.\n");
   //This is the preferred method of ending a thread in C, but not in C++, according to MSDN.
   //ExitThread(0);

   return 0;
}

/**
 * @brief Creates (and starts) the message processing thread.
 * @pre The messaging window has been created.
 */
void MCT_createMessageProcessingThread(void)
{
   MCT_debugMsg("MCT_createMessageProcessingThread() - Creating thread...\n");
   MCT_messageProcessingThread = CreateThread(NULL, 0, MCT_messagePump, NULL, 0, &MCT_messagePumpThreadID);
   MCT_debugMsg("MCT_createMessageProcessingThread() - Thread created.\n");
}

/*********************************
 *       STARTUP/SHUTDOWN        *
 *********************************/

/**
 * @brief Creates the CRITICAL_SECTION, for cross-thread exclusion.
 * @note This MUST occur before starting the message processing thread.
 */
void MCT_initializeCriticalSection(void)
{
    if (MCT_criticalSection != NULL)
       return;

    MCT_debugMsg("MCT_initializeCriticalSection() - Initializing MCT_criticalSection...\n");
    MCT_criticalSection = (CRITICAL_SECTION *)calloc(sizeof(CRITICAL_SECTION), 1);
    InitializeCriticalSection(MCT_criticalSection);
    MCT_debugMsg("MCT_initializeCriticalSection() - MCT_criticalSection initialized.\n");

    return;
}

/**
 * @brief Initialize the Windows messaging, an MCT_state array, and other basic functionality.
 *        Register all window messages. Start a message processing thread (which will create its own window).
 */
void MCT_init(void)
{
   LARGE_INTEGER performanceFrequencyResult;

   if (MCT_initialized)
   {
      MCT_debugMsg("MCT_init() - Already initialized. Cancelling/ignoring initialization request.\n");
      return;
   }

   MCT_debugMsg("MCT_init() - Initializing performancePeriod...\n");
   QueryPerformanceFrequency(&performanceFrequencyResult);
   MCT_performancePeriod = 1.0 / (double)performanceFrequencyResult.QuadPart;//Inverse of ticks per second. Cache the division.
   MCT_debugMsg("MCT_init() - MCT_performancePeriod = %3.4f [S/tick] from %llu [ticks/S]\n", MCT_performancePeriod, performanceFrequencyResult.QuadPart);

   MCT_initializeCriticalSection();

   MCT_debugMsg("MCT_init() - Initializing MCT_amplifiers array...\n");
   MCT_amplifiers = (MCT_state **)calloc(1, sizeof(MCT_state **));
   MCT_resizeAmplifiersArray(4);//4 is a reasonable default, that's 2 amplifiers with 2 channels each. Few, if any, use more than that, and the memory's cheap.

   MCT_debugMsg("MCT_init() - Registering window messages...\n");
   MCT_MCTGOpenMessage = RegisterWindowMessage(MCTG_OPEN_MESSAGE_STR);
   MCT_MCTGCloseMessage = RegisterWindowMessage(MCTG_CLOSE_MESSAGE_STR);
   MCT_MCTGRequestMessage = RegisterWindowMessage(MCTG_REQUEST_MESSAGE_STR);
   MCT_MCTGReconnectMessage = RegisterWindowMessage(MCTG_RECONNECT_MESSAGE_STR);
   MCT_MCTGBroadcastMessage = RegisterWindowMessage(MCTG_BROADCAST_MESSAGE_STR);
   MCT_MCTGIDMessage = RegisterWindowMessage(MCTG_ID_MESSAGE_STR);
   MCT_SHUTDOWN = RegisterWindowMessage("MCT_SHUTDOWN");
   MCT_debugMsg("MCT_init() - Window messages:\n\t"
                "MCT_MCTGOpenMessage:      %p\n\t"
                "MCT_MCTGCloseMessage:     %p\n\t"
                "MCT_MCTGRequestMessage:   %p\n\t"
                "MCT_MCTGReconnectMessage: %p\n\t"
                "MCT_MCTGBroadcastMessage: %p\n\t"
                "MCT_MCTGIDMessage:        %p\n\t"
                "MCT_SHUTDOWN:             %p\n",
                MCT_MCTGOpenMessage, MCT_MCTGCloseMessage,
                MCT_MCTGRequestMessage, MCT_MCTGReconnectMessage, 
                MCT_MCTGBroadcastMessage, MCT_MCTGIDMessage,
                MCT_SHUTDOWN);

   MCT_createMessageProcessingThread();

   MCT_initialized = 1;

   return;
}

/**
 * @brief Clean up and shut down the module.
 *
 * Release all dynamic memory and stop the message processing thread.
 */
void MCT_shutdown(void)
{
   int i;

   if (!MCT_initialized)
   {
      MCT_debugMsg("MCT_shutdown() - Initialization has not been performed. Cancelling/ignoring shutdown request.\n");
      return;
   }
   
   MCT_debugMsg("MCT_shutdown() - Signalling message processing thread: MCT_SHUTDOWN\n");
   MCT_messageThreadShutdown = TRUE;
   PostMessage(MCT_hwnd, MCT_SHUTDOWN, NULL, NULL);
   PostThreadMessage(MCT_messagePumpThreadID, MCT_SHUTDOWN, NULL, NULL);

   MCT_debugMsg("MCT_shutdown() - Waiting for message processing thread to shutdown.\n");
   SwitchToThread();//Yield the CPU, so the messaging thread (hopefully) takes control.
   switch (WaitForSingleObject(MCT_messageProcessingThread, 5000)) //Wait ~5 second(s).
   {
      case WAIT_ABANDONED:
         MCT_debugMsg("MCT_shutdown() - WaitForSingleObject(MCT_messagePumpThread) = WAIT_ABANDONDED\n");
         break;
      case WAIT_OBJECT_0:
         MCT_debugMsg("MCT_shutdown() - WaitForSingleObject(MCT_messagePumpThread) = WAIT_OBJECT_0\n");
         break;
      case WAIT_TIMEOUT:
         MCT_debugMsg("MCT_shutdown() - WaitForSingleObject(MCT_messagePumpThread) = WAIT_TIMEOUT\n");
         MCT_debugMsg("MCT_shutdown() - Re-waiting for message processing thread to shutdown.\n");
         SwitchToThread();
         switch (WaitForSingleObject(MCT_messageProcessingThread, 5000))
         {
            case WAIT_ABANDONED:
               MCT_debugMsg("MCT_shutdown() - WaitForSingleObject(MCT_messagePumpThread) = WAIT_ABANDONDED\n");
               break;
            case WAIT_OBJECT_0:
               MCT_debugMsg("MCT_shutdown() - WaitForSingleObject(MCT_messagePumpThread) = WAIT_OBJECT_0\n");
               break;
            case WAIT_TIMEOUT:
               MCT_debugMsg("MCT_shutdown() - WaitForSingleObject(MCT_messagePumpThread) = WAIT_TIMEOUT\n");
               break;
            default:
               MCT_debugMsg("MCT_shutdown() - WaitForSingleObject(MCT_messagePumpThread) = Unrecognized return value ???\n");
         }
         break;
      default:
         MCT_debugMsg("MCT_shutdown() - WaitForSingleObject(MCT_messagePumpThread) = Unrecognized return value ???\n");
   }

   if (MCT_messageThreadRunning)
   {
      //We could have segfaults now, if the thread tries to access memory after it gets cleared below.
      MCT_errorMsg("MCT_shutdown() - MCT_messageProcessingThread appears to still be running. Continuing with shutdown procedure anyway.\n");
   }

   if (MCT_amplifiers != NULL)
   {
      MCT_debugMsg("MCT_shutdown() - Clearing MCT_amplifiers array.\n");

      MCT_debugMsg("MCT_shutdown() - Entering critical section...\n");
      EnterCriticalSection(MCT_criticalSection);
      for (i = 0; i < MCT_amplifiersLength; i++)
         MCT_stateDestroy(&MCT_amplifiers[i]);

      free(MCT_amplifiers);
      MCT_debugMsg("MCT_shutdown() - Leaving critical section...\n");
      LeaveCriticalSection(MCT_criticalSection);
   }

   MCT_initialized = 0;
}

/*********************************
 *        DATA FUNCTIONS         *
 *********************************/
/**
 * @brief Compute a factor, such that when multiplied by the voltage (in Volts) on the primary/scaled output, the result will be in the units specified by <tt>MCT_getUnits</tt>.
 * @arg <tt>state</tt> - A valid <tt>MCT_state</tt> pointer.
 * @return A value which, when multiplied by the recorded signal [V] of the primary/scaled output will convert it into the appropriate unit as determined by <tt>MCT_getUnits</tt>.
 */
double MCT_getScaledGain(MCT_state* state)
{
   return  state->dAlpha * state->dScaleFactor;  
   
}

/**
 * @brief Return the units, as a string, that corresponds to the scale factor returned by <tt>MCT_getScaleGain</tt>.
 * @arg <tt>state</tt> - A valid <tt>MCT_state</tt> pointer.
 * @return The units corresponding to the result of <tt>MCT_getScaleGain</tt> (ie. "nA").
 */
char* MCT_getScaledUnits(MCT_state* state)
{

	switch (state->uScaleFactorUnits)
	{
	case 0:
		return "V";
	case 1:
		return "mV";
	case 2:
		return "uV";
	case 3:
		return "A";
	case 4:
		return "mA";
	case 5:
		return "uA";
	case 6:
		return "nA";
	case 7: 
		return "pA";
	default:
		return "???";
	}

}



/**********************************
 **********************************
 * PROGRAM CONTROL/USER INTERFACE *
 **********************************
 **********************************/

#ifdef MATLAB_MEX_FILE
/**********************************
 *          MEX INTERFACE         *
 **********************************/
///@brief A central <tt>mwSize</tt> for use when creating mxArrays.
mwSize MCT_mxDims[2] = {1, 1};//Global 1x1 array indicator, as this is very common.
///@brief The set of field names that define the mxArray equivalent of an <tt>MCT_state</tt> struct.
const char* MCT_mxFieldNames[] = {"ID", "uOperatingMode", "uScaledOutSignal", "dAlpha", "dScaleFactor", "uScaleFactorUnits", 
   "dLPFCutoff", "dMembraneCap", "dExtCmdSens", "uRawOutSignal", "dRawScaleFactor", "uRawScaleFactorUnits", 
   "uHardwareType", "dSecondaryAlpha", "dSecondaryLPFCutoff", "szAppVersion", "szFirmwareVersion",
   "szDSPVersion", "szSerialNumber", "stateAge", "uComPortID", "uAxoBusID", "uChannelID", "uSerialNum"};

/**
 * @brief Convert an ID value into an mxArray.
 * @arg <tt>ID</tt> - The ID to be converted into an mxArray.
 * @arg <tt>mxID</tt> - A pointer to the mxArray pointer in which to place the 16-bit ID. Must point to NULL.
 */
mxArray* MCT_IDTomxArray(LPARAM ID)
{
   UINT* IDptr;
   mxArray* mxID;

   MCT_debugMsg("MCT_IDTomxArray(0x%p)\n", ID);
   /*if (*mxID != NULL)
   {
      MCT_errorMsg("MCT_mxArrayToID - The mxID argument must point to NULL, not @%p\n", mxID);
      return;
   }*/

   mxID = mxCreateNumericArray(2, MCT_mxDims, mxUINT32_CLASS, mxREAL);
   IDptr = (UINT*)mxGetData(mxID);
   *IDptr = ID;
      
   return mxID;
}

/**
 * @brief Convert an mxArray value into an ID.
 * @arg <tt>mxID</tt> - The mxArray containing the 16-bit ID, or the uComPortID/uAxoBusID/uChannelID, or uSerialNum/uChannelID.
 * @return The 16 bit unsigned integer corresponding to the ID.
 */
LPARAM MCT_mxArrayToID(mxArray* mxID)
{
  double *ptr;
  mwSize numEl;
  unsigned int uComPortID, uAxoBusID, uChannelID, uSerialNum = 0;
  
  ptr = mxGetPr(mxID);
  numEl = mxGetNumberOfElements(mxID);
  if (numEl == 1)
  {
     return (LPARAM)*ptr;
  }
  else if (numEl == 2)
  {
     uSerialNum = ptr[0];
     uChannelID = ptr[1];
         
     //MCTG_Pack700BSignalIDs(UINT uComPortID, UINT uAxoBusID, UINT uChannelID)
     return MCTG_Pack700BSignalIDs(uSerialNum, uChannelID);
  }
  else if (numEl == 3)
  {
     uComPortID = ptr[0];
     uAxoBusID = ptr[1];
     uChannelID = ptr[2];
         
     //MCTG_Pack700BSignalIDs(UINT uComPortID, UINT uAxoBusID, UINT uChannelID)                          
     return MCTG_Pack700ASignalIDs(uComPortID, uAxoBusID, uChannelID);
  }
  else
     mexErrMsgTxt("MCT_mxArrayToID - Invalid mxID. Must be a 1, 2, or 3 element array.");

  return 0;
}

/**
 * @brief Convert an MCT_state struct into its Matlab equivalent.
 * @arg <tt>state</tt> - The state to be converted.
 * @arg <tt>mxStruct</tt> - The memory location in which to create the mxArray object. The value pointed to must be NULL.
 */
void MCT_state2mxStruct(MCT_state* state, mxArray** mxStruct)
{
   unsigned int uComPortID, uAxoBusID, uChannelID, uSerialNum = 0;
   //mxArray* mxID;
   #ifdef MCT_DEBUG
      char stateStr[1024];
   #endif

   #ifdef MCT_DEBUG
   MCT_stateToString(state, stateStr, 1024);
   #endif
   MCT_debugMsg("MCT_state2mxStruct(...) - Converting state: \n  %s\n", stateStr);

   if (state == NULL)
      mexErrMsgTxt("MCT_state2mxStruct - The state argument must not be NULL");


   if (*mxStruct != NULL)
   {
      MCT_errorMsg("MCT_state2mxStruct - The mxStruct argument must point to NULL, not @%p\n", mxStruct);
      return;
   }

   //TO031409A - Make sure to set the MCT_mxDims value(s) here, otherwise they could be crufty. -- Tim O'Connor 3/14/09
   MCT_mxDims[0] = 1;
   MCT_mxDims[1] = 1;

   *mxStruct = mxCreateStructArray(2, MCT_mxDims, 24, MCT_mxFieldNames);
   //MCT_IDTomxArray(state->ID, &mxID);
   //mxSetField(*mxStruct, 0, "ID", mxID);
   mxSetField(*mxStruct, 0, "ID", MCT_IDTomxArray(state->ID));
   mxSetField(*mxStruct, 0, "uOperatingMode", mxCreateString(MCTG_MODE_NAMES[state->uOperatingMode]));
   mxSetField(*mxStruct, 0, "uScaledOutSignal", mxCreateString(MCT_getScaledOutSignalShortName(state)));
   mxSetField(*mxStruct, 0, "dAlpha", mxCreateDoubleScalar(state->dAlpha));
   mxSetField(*mxStruct, 0, "dScaleFactor", mxCreateDoubleScalar(state->dScaleFactor));
   mxSetField(*mxStruct, 0, "uScaleFactorUnits", mxCreateString(MCT_getScaleFactorUnitsString(state)));//FIND_ME
   mxSetField(*mxStruct, 0, "dLPFCutoff", mxCreateDoubleScalar(state->dLPFCutoff));
   mxSetField(*mxStruct, 0, "dMembraneCap", mxCreateDoubleScalar(state->dMembraneCap));
   mxSetField(*mxStruct, 0, "dExtCmdSens", mxCreateDoubleScalar(state->dExtCmdSens));
   mxSetField(*mxStruct, 0, "uRawOutSignal", mxCreateString("NOT_YET_IMPLEMENTED"));//mxCreateString(MCTG_OUT_GLDR_SHORT_NAMES[state->uRawOutSignal]));
   mxSetField(*mxStruct, 0, "dRawScaleFactor", mxCreateDoubleScalar(state->dRawScaleFactor));
   mxSetField(*mxStruct, 0, "uRawScaleFactorUnits", mxCreateString("NOT_YET_IMPLEMENTED"));//mxCreateString(MCT_SCALE_UNITS[state->uRawScaleFactorUnits]));
   mxSetField(*mxStruct, 0, "uHardwareType", mxCreateString(MCTG_HW_TYPE_NAMES[state->uHardwareType]));
   mxSetField(*mxStruct, 0, "dSecondaryAlpha", mxCreateDoubleScalar(state->dSecondaryAlpha));
   mxSetField(*mxStruct, 0, "dSecondaryLPFCutoff", mxCreateDoubleScalar(state->dSecondaryLPFCutoff));
   mxSetField(*mxStruct, 0, "szAppVersion", mxCreateString(state->szAppVersion));
   mxSetField(*mxStruct, 0, "szFirmwareVersion", mxCreateString(state->szFirmwareVersion));
   mxSetField(*mxStruct, 0, "szDSPVersion", mxCreateString(state->szDSPVersion));
   mxSetField(*mxStruct, 0, "szSerialNumber", mxCreateString(state->szSerialNumber));
   mxSetField(*mxStruct, 0, "stateAge", mxCreateDoubleScalar(MCT_ticksToSeconds(state->refreshTickCount)));
   if (state->uHardwareType == MCTG_HW_TYPE_MC700A)
   {
      MCTG_Unpack700ASignalIDs(state->ID, &uComPortID, &uAxoBusID, &uChannelID);
      mxSetField(*mxStruct, 0, "uComPortID", mxCreateDoubleScalar(uComPortID));
      mxSetField(*mxStruct, 0, "uAxoBusID", mxCreateDoubleScalar(uAxoBusID));
      mxSetField(*mxStruct, 0, "uChannelID", mxCreateDoubleScalar(uChannelID));
      mxSetField(*mxStruct, 0, "uSerialNum", mxCreateDoubleScalar(0));
   }
   else if (state->uHardwareType == MCTG_HW_TYPE_MC700B)
   {
      MCTG_Unpack700BSignalIDs(state->ID, &uSerialNum, &uChannelID);
      mxSetField(*mxStruct, 0, "uSerialNum", mxCreateDoubleScalar(uSerialNum));
      mxSetField(*mxStruct, 0, "uChannelID", mxCreateDoubleScalar(uChannelID));
      mxSetField(*mxStruct, 0, "uComPortID", mxCreateDoubleScalar(0));
      mxSetField(*mxStruct, 0, "uAxoBusID", mxCreateDoubleScalar(0));
   }

   MCT_debugMsg("Created mxArray struct from @%p in @%p.\n", state, *mxStruct);
   
   return;
}

/**
 * @brief Standard Matlab Mex file entry point.
 * @see \htmlonly <a href="../../../resources/MultiClampTelegraph.m">MultiClampTelegraph.m</a> \endhtmlonly for documentation.
 * @arg <tt>nlhs</tt> - The number of left-hand-side arguments.
 * @arg <tt>plhs</tt> - The left-hand-side arguments.
 * @arg <tt>nrhs</tt> - The number of right-hand-side arguments.
 * @arg <tt>prhs</tt> - The right-hand-side arguments.
 */
void mexFunction(int nlhs, mxArray** plhs, int nrhs, mxArray** prhs)
{
   //i and j increment as we consume left/right hand side arguments.
   //k, h, and count may be used as necessary in handling a given command (make sure to locally initialize them).
   //index is used as a place to store the output of a MCT_getAmplifierIndex look-up.
   int i, j, k, h, count, index;
   char* command;
   mxArray* tempVal;//Initialize locally, as usual. Clean up when done.
   unsigned int uComPortID, uAxoBusID, uChannelID, uSerialNum;

   mexAtExit(MCT_shutdown);//Register the shutdown hook, so it's executed when the mex file is cleared.
   MCT_init();

   j = 0;
   for (i = 0; i < nrhs; i++)
   {
      command = mxArrayToString(prhs[i]);

      MCT_debugMsg("mexFunction(...) - Processing command: '%s'...\n", command);

      if (_strcmpi(command, "broadcast") == 0)
         MCT_broadcast();
      else if (_strcmpi(command, "getAmplifier") == 0)
      {
         if (i >= nrhs - 1)
            mexErrMsgTxt("Invalid number of arguments. 'getState' must be followed by an ID");
         if (j >= nlhs)
            mexErrMsgTxt("Not enough return arguments available.");

         MCT_debugMsg("mexFunction() - Entering critical section...\n");
         EnterCriticalSection(MCT_criticalSection);

         index = MCT_getAmplifierIndex(MCT_mxArrayToID(prhs[++i]));
         if (index < 0)
         {
           MCT_debugMsg("mexFunction() - Leaving critical section...\n");
           LeaveCriticalSection(MCT_criticalSection);
           mexErrMsgTxt("No amplifier found with requested ID");
           return;//mexErrMsgTxt terminates execution anyway, this is just here to make that obvious.
         }

         MCT_state2mxStruct(MCT_amplifiers[index], &plhs[j++]);

         MCT_debugMsg("mexFunction() - Leaving critical section...\n");
         LeaveCriticalSection(MCT_criticalSection);
      }
      else if (_strcmpi(command, "getAllAmplifiers") == 0)
      {
         MCT_debugMsg("mexFunction() - Entering critical section...\n");
         EnterCriticalSection(MCT_criticalSection);

         //Initialize a correctly sized cell array.
         count = 0;
         for (k = 0; k < MCT_amplifiersLength; k++)
         {
           if (MCT_amplifiers[k] != NULL)
              count++;
         }

         MCT_mxDims[0] = count;
         MCT_mxDims[1] = 1;
         plhs[j++] = mxCreateCellArray(2, MCT_mxDims);
         //Populate the cell array.
         h = 0;
         for (k = 0; k < MCT_amplifiersLength; k++)
         {
            if (MCT_amplifiers[k] != NULL)
            {
               tempVal = NULL;
               MCT_state2mxStruct(MCT_amplifiers[k], &tempVal);
               mxSetCell(plhs[j - 1], (mwIndex)h++, tempVal);
            }
         }

         MCT_debugMsg("mexFunction() - Leaving critical section...\n");
         LeaveCriticalSection(MCT_criticalSection);
      }
      else if (_strcmpi(command, "requestTelegraph") == 0)
         MCT_requestTelegraph(MCT_mxArrayToID(prhs[++i]));
      else if (_strcmpi(command, "displayAllAmplifiers") == 0)
         MCT_displayAmplifiers();
      else if (_strcmpi(command, "shutdown") == 0)
         MCT_shutdown();
      else if (_strcmpi(command, "version") == 0)
         MCT_printMsg("MulticlampTelegraph Version: %s\n", MCT_VERSION);
      else if (_strcmpi(command, "openConnection") == 0)
         MCT_openConnection(MCT_mxArrayToID(prhs[++i]));
      else if (_strcmpi(command, "closeConnection") == 0)
         MCT_closeConnection(MCT_mxArrayToID(prhs[++i]));
      else if (_strcmpi(command, "get700AID") == 0)
      {
         if (!(mxIsUint32(prhs[i + 1]) && mxIsUint32(prhs[i + 2]) && mxIsUint32(prhs[i + 3])))
            mexErrMsgTxt("uComPortID, uAxoBusID, and uChannelID must be of type uint32.");

         uComPortID = *((UINT*)mxGetData(prhs[++i]));
         uAxoBusID = *((UINT*)mxGetData(prhs[++i]));
         uChannelID = *((UINT*)mxGetData(prhs[++i]));

         plhs[j] = MCT_IDTomxArray(MCTG_Pack700ASignalIDs(uComPortID, uAxoBusID, uChannelID));
      }
      else if (_strcmpi(command, "get700BID") == 0)
      {
         if (!(mxIsUint32(prhs[i + 1]) && mxIsUint32(prhs[i + 2])))
            mexErrMsgTxt("uSerialNum and uChannelID must be of type uint32.");
            
         uSerialNum = *((UINT*)mxGetData(prhs[++i]));
         uChannelID = *((UINT*)mxGetData(prhs[++i]));

         plhs[j++] = MCT_IDTomxArray(MCTG_Pack700BSignalIDs(uSerialNum, uChannelID));
      }
      else if (_strcmpi(command, "getScaledGain") == 0)
      {
         index = MCT_getAmplifierIndex(MCT_mxArrayToID(prhs[++i]));
         if (index < 0)
         {
           mexErrMsgTxt("No amplifier found with requested ID");
           return;//mexErrMsgTxt terminates execution anyway, this is just here to make that obvious.
         }

         plhs[j++] = mxCreateDoubleScalar(MCT_getScaledGain(MCT_amplifiers[index]));
      }
      else if (_strcmpi(command, "getMode") == 0)
      {
         index = MCT_getAmplifierIndex(MCT_mxArrayToID(prhs[++i]));
         if (index < 0)
         {
           mexErrMsgTxt("No amplifier found with requested ID");
           return;//mexErrMsgTxt terminates execution anyway, this is just here to make that obvious.
         }

         plhs[j++] = mxCreateString(MCTG_MODE_NAMES[MCT_amplifiers[index]->uOperatingMode]);
      }
      else if (_strcmpi(command, "getScaledUnits") == 0)
      {
         index = MCT_getAmplifierIndex(MCT_mxArrayToID(prhs[++i]));
         if (index < 0)
         {
           mexErrMsgTxt("No amplifier found with requested ID");
           return;//mexErrMsgTxt terminates execution anyway, this is just here to make that obvious.
         }

         plhs[j++] = mxCreateString(MCT_getScaledUnits(MCT_amplifiers[index]));
      }
      else
      {
         MCT_errorMsg("Unrecognized command: '%s'\n", command);
         mexErrMsgTxt("Unrecognized command.");
      }
   }

   return;
}
#else
/**********************************
 *     COMMAND-LINE INTERFACE     *
 **********************************/

/**
 * @brief Standard C-language executable entry point.
 * @arg <tt>argc</tt> - The number of command-line arguments.
 * @arg <tt>argv</tt> - The command-line arguments.
 */
int main(int argc, char** argv)
{
   int i = 0;
   DWORD sleepTime = 15000;

   //Start-up (initialize state array, start message processing thread, create window, broadcast for Multiclamp instances, etc).
   MCT_init();

   for (i = 0; i < 3; i++)
   {   
      //Broadcast a request for Multiclamp Commanders to identify themselves.
      MCT_broadcast();

      //Wait a while, for broadcasts to recieve responses, and to dump debug messages to see what happened.
      printf("%s:main(...) - Sleeping for %3.2f seconds...\n", argv[0], ((unsigned int)sleepTime) / 1000.0);
      Sleep(sleepTime);
      printf("%s:main(...) - Waking up.\n", argv[0]);
   }
   
   //Broadcast a request for Multiclamp Commanders to identify themselves.
   MCT_broadcast();
   
   //Okay, now shut down cleanly.
   MCT_shutdown();

   return 0;
}
#endif
