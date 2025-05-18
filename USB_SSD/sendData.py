import pyaudio
import numpy as np
import serial
import time
import math
import argparse

FORMAT = pyaudio.paInt16
CHANNELS = 1
RATE = 44100
CHUNK = 1024

def setup_audio():
    audio = pyaudio.PyAudio()
    stream = audio.open(format=FORMAT, channels=CHANNELS,
                        rate=RATE, input=True,
                        frames_per_buffer=CHUNK)
    return audio, stream

def setup_serial(port, baud_rate):
    try:
        ser = serial.Serial(port, baud_rate, timeout=1)
        print(f"Connected to {port} at {baud_rate} baud")
        return ser
    except serial.SerialException as e:
        print(f"Error opening serial port: {e}")
        available_ports = list_serial_ports()
        if available_ports:
            print("Available ports:")
            for p in available_ports:
                print(f"  {p}")
        exit(1)

def list_serial_ports():
    import serial.tools.list_ports
    return [p.device for p in serial.tools.list_ports.comports()]

def calculate_db(audio_data):
    data = np.frombuffer(audio_data, dtype=np.int16)
    
    rms = np.sqrt(np.mean(np.square(data)))
    
    if rms > 0:
        db = 20 * math.log10(rms / 32768)
    else:
        db = -96
    
    normalized_db = int(max(0, min(99, (db + 96) * 99 / 96)))
    return normalized_db

def main(port, baud_rate, update_rate):
    audio, stream = setup_audio()
    ser = setup_serial(port, baud_rate)
    
    update_interval = 1.0 / update_rate
    
    try:
        print("Recording started. Press Ctrl+C to stop.")
        print("Sending decibel levels to FPGA...")
        
        last_update_time = time.time()
        
        while True:
            current_time = time.time()
            
            if current_time - last_update_time >= update_interval:
                audio_data = stream.read(CHUNK, exception_on_overflow=False)
                
                db_level = calculate_db(audio_data)
                
                db_str = f"{db_level:02d}"
                ser.write(db_str.encode())
                
                print(f"Sending dB level: {db_str} ({current_time:.2f}s)", end="\r")
                
                last_update_time = current_time
    
    except KeyboardInterrupt:
        print("\nRecording stopped.")
    finally:
        stream.stop_stream()
        stream.close()
        audio.terminate()
        ser.close()
        print("Resources released.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Microphone decibel meter with FPGA display')
    parser.add_argument('--port', '-p', type=str, default='COM3', 
                        help='Serial port for USBUART PMOD (e.g., COM3 on Windows, /dev/ttyUSB0 on Linux)')
    parser.add_argument('--baud', '-b', type=int, default=9600, 
                        help='Baud rate for serial communication')
    parser.add_argument('--rate', '-r', type=float, default=10.0, 
                        help='Update rate in Hz (updates per second)')
    
    args = parser.parse_args()
    
    print(f"Starting with port={args.port}, baud rate={args.baud}, update rate={args.rate}Hz")
    main(args.port, args.baud, args.rate)
