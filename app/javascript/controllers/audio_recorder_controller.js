import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput", "recordButton", "status", "textArea"]
  static outputSampleRate = 16000

  connect() {
    this.resetRecorder()
  }

  async toggle() {
    if (this.recording) {
      await this.stop()
    } else {
      await this.start()
    }
  }

  async start() {
    try {
      this.resetRecorder()
      this.stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      this.audioContext = new AudioContext()
      this.sampleRate = this.audioContext.sampleRate
      this.source = this.audioContext.createMediaStreamSource(this.stream)
      this.processor = this.audioContext.createScriptProcessor(4096, 1, 1)

      this.processor.onaudioprocess = (event) => {
        if (!this.recording) return

        const input = event.inputBuffer.getChannelData(0)
        this.buffers.push(new Float32Array(input))
        event.outputBuffer.getChannelData(0).fill(0)
      }

      this.source.connect(this.processor)
      this.processor.connect(this.audioContext.destination)
      this.recording = true
      this.setRecordingState(true)
    } catch (_error) {
      this.statusTarget.textContent = "Microphone access was blocked."
      this.cleanup()
    }
  }

  async stop() {
    if (!this.recording) return

    this.recording = false
    this.setRecordingState(false)
    await this.cleanup()
    this.attachRecording()
  }

  attachRecording() {
    const samples = this.downsample(this.mergeBuffers(), this.sampleRate, this.constructor.outputSampleRate)
    const wav = this.encodeWav(samples, this.constructor.outputSampleRate)
    const blob = new Blob([wav], { type: "audio/wav" })

    if (blob.size < 2048) {
      this.statusTarget.textContent = "Recording was too short. Please try again."
      return
    }

    const file = new File([blob], `voice-message-${Date.now()}.wav`, { type: "audio/wav" })
    const transfer = new DataTransfer()

    transfer.items.add(file)
    this.fileInputTarget.files = transfer.files
    this.textAreaTarget.required = false
    this.statusTarget.textContent = "Sending voice message..."
    this.element.requestSubmit()
  }

  mergeBuffers() {
    const length = this.buffers.reduce((sum, buffer) => sum + buffer.length, 0)
    const result = new Float32Array(length)
    let offset = 0

    this.buffers.forEach((buffer) => {
      result.set(buffer, offset)
      offset += buffer.length
    })

    return result
  }

  encodeWav(samples, sampleRate) {
    const buffer = new ArrayBuffer(44 + samples.length * 2)
    const view = new DataView(buffer)

    this.writeString(view, 0, "RIFF")
    view.setUint32(4, 36 + samples.length * 2, true)
    this.writeString(view, 8, "WAVE")
    this.writeString(view, 12, "fmt ")
    view.setUint32(16, 16, true)
    view.setUint16(20, 1, true)
    view.setUint16(22, 1, true)
    view.setUint32(24, sampleRate, true)
    view.setUint32(28, sampleRate * 2, true)
    view.setUint16(32, 2, true)
    view.setUint16(34, 16, true)
    this.writeString(view, 36, "data")
    view.setUint32(40, samples.length * 2, true)

    this.writePcmSamples(view, 44, samples)

    return view
  }

  downsample(samples, inputSampleRate, outputSampleRate) {
    if (inputSampleRate === outputSampleRate) return samples

    const ratio = inputSampleRate / outputSampleRate
    const outputLength = Math.floor(samples.length / ratio)
    const output = new Float32Array(outputLength)

    for (let index = 0; index < outputLength; index++) {
      const start = Math.floor(index * ratio)
      const end = Math.floor((index + 1) * ratio)
      let sum = 0
      let count = 0

      for (let sampleIndex = start; sampleIndex < end && sampleIndex < samples.length; sampleIndex++) {
        sum += samples[sampleIndex]
        count += 1
      }

      output[index] = count > 0 ? sum / count : 0
    }

    return output
  }

  writePcmSamples(view, offset, samples) {
    samples.forEach((sample) => {
      const clampedSample = Math.max(-1, Math.min(1, sample))
      view.setInt16(offset, clampedSample < 0 ? clampedSample * 0x8000 : clampedSample * 0x7fff, true)
      offset += 2
    })
  }

  writeString(view, offset, string) {
    Array.from(string).forEach((character, index) => {
      view.setUint8(offset + index, character.charCodeAt(0))
    })
  }

  setRecordingState(isRecording) {
    this.recordButtonTarget.textContent = isRecording ? "Stop" : "Record"
    this.recordButtonTarget.classList.toggle("recording", isRecording)
    this.statusTarget.textContent = isRecording ? "Recording..." : "Processing..."
  }

  async cleanup() {
    this.processor?.disconnect()
    this.source?.disconnect()
    this.stream?.getTracks().forEach((track) => track.stop())

    if (this.audioContext?.state !== "closed") {
      await this.audioContext.close()
    }
  }

  resetRecorder() {
    this.recording = false
    this.buffers = []
    this.stream = null
    this.audioContext = null
    this.source = null
    this.processor = null
    this.sampleRate = 44100
  }
}
