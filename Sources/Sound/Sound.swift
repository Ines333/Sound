import SwiftIO
import MadBoard

@main
public struct Sound {
    
    public static func main() {
        let speaker = I2SOut(Id.I2SOut0)


        let frameRate = 11025

        let cFrequency: Float = 261.63
        let eFrequency: Float = 329.63
        let gFrequency: Float = 392.00

        let cSampler = tri(frequency: cFrequency)
        let eSampler = tri(frequency: eFrequency)
        let gSampler = tri(frequency: gFrequency)
        let lowgSampler = tri(frequency: gFrequency / 2)

        var buffer0 = [Int16](repeating: 0, count: 100_000)


        // play(sampler: cSampler, data: &buffer0)
        // play(sampler: both(cSampler, eSampler), data: &buffer0)
        // play(sampler: both(note(cSampler, start: 0, end: 1/4), note(eSampler, start: 1/2, end: 1)), data: &buffer0)
        play(sampler: both(marioAt(1), marioAt(1/2)), data: &buffer0)


        while true {

        }

        func encode(_ x: Float) -> Int16 {
            return Int16(16384 * x)
        }

        func tri(frequency: Float, _ amplitude: Float = 0.3) -> (Int) -> Float {
            let period = Float(frameRate) / frequency

            func sampler(t: Int) -> Float {
                let sawWave = Float(t) / period - Float(Int(Float(t) / period + 0.5))
                let triWave = 2 * abs(2 * sawWave) - 1

                return amplitude * triWave
            }

            return sampler
        }

        func both(
            _ f: @escaping (Int) -> Float,
            _ g: @escaping (Int) -> Float
        ) -> (Int) -> Float {
            return { t in f(t) + g(t) }
        }


        func note(
            _ f: @escaping (Int) -> Float, 
            start: Float, end: Float, 
            fade: Float = 0.01
        ) -> (Int) -> Float {
            func sampler(t: Int) -> Float {
                let seconds = Float(t) / Float(frameRate)

                if seconds < start || seconds > end {
                    return 0
                } else if seconds < start + fade {
                    return (seconds - start) / fade * f(t)
                } else if seconds > end - fade {
                    return (end - seconds) / fade * f(t)
                } else {
                    return f(t)
                }
            }

            return sampler
        }

        func marioAt(_ octave: Float)  -> (Int) -> Float {
            return mario(tri(frequency: cFrequency * octave), 
                            tri(frequency: eFrequency * octave),
                            tri(frequency: gFrequency * octave),
                            tri(frequency: gFrequency / 2 * octave))
        }


        func mario(
            _ cSampler: @escaping (Int) -> Float, 
            _ eSampler: @escaping (Int) -> Float,
            _ gSampler: @escaping (Int) -> Float,
            _ lowgSampler: @escaping (Int) -> Float
        ) -> (Int) -> Float {
            var z: Float = 0
            var song = note(eSampler, start: z, end: z + 1/8)
            z += 1/8
            song = both(song, note(eSampler, start: z, end: z + 1/8))
            z += 1/4
            song = both(song, note(eSampler, start: z, end: z + 1/8))
            z += 1/4
            song = both(song, note(cSampler, start: z, end: z + 1/8))
            z += 1/8
            song = both(song, note(eSampler, start: z, end: z + 1/8))
            z += 1/4
            song = both(song, note(gSampler, start: z, end: z + 1/4))
            z += 1/2
            song = both(song, note(lowgSampler, start: z, end: z + 1/4))
            z += 1/2

            return song
        }


        func play(sampler: (Int) -> Float, data: inout [Int16], second: Int = 2) {
            for i in 0..<second*frameRate {
                let sample = sampler(i)
                data[i*2] = encode(sample)
                data[i*2+1] = encode(sample)
            }

            data.withUnsafeBytes { ptr in
                let u8Array = ptr.bindMemory(to: UInt8.self)
                speaker.write(Array(u8Array))
            }
        }



    }

}



