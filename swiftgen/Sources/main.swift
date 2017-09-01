import Foundation
import CommandLineKit

let cli = CommandLineKit.CommandLine()
let generator = PerlinGenerator()

let optOctaves = IntOption(shortFlag: "o", longFlag: "octaves", required: true, helpMessage: "Number of octaves")
let optZoom = DoubleOption(shortFlag: "z", longFlag: "zoom", required: true, helpMessage: "Level of zoom")
let optPersistence = DoubleOption(shortFlag: "p", longFlag: "persistence", required: true, helpMessage: "Level of persistence")

cli.addOptions(optOctaves, optZoom, optPersistence)

do {
	try cli.parse()
} catch {
	cli.printUsage(error)
	exit(EX_USAGE)
}

generator.octaves = optOctaves.value!
generator.zoom = Float(optZoom.value!)
generator.persistence = Float(optPersistence.value!)

let chunkSize = 10
//let n = chunkSize * 24
let n = chunkSize*24*365*2

var timestamp = 1483228800

let rawNoise = (0..<n).map {
	i in
	return (10.0/Float(generator.octaves))*(generator.perlinNoise(Float(i)/100, y: Float(i)/100, z: 0, t: 0))
}

let bias = abs(rawNoise.min()!) + 0.1
let noise = rawNoise.map { $0 + bias }

let chunks = stride(from: 0, to: noise.count, by: chunkSize).map {
	Array(noise[$0..<min($0 + chunkSize, noise.count)])
	}
let ohlc = chunks.map {
	row -> (Int, Float, Float, Float, Float) in
		timestamp = timestamp + 3600
		return (timestamp, row.first!, row.max()!, row.min()!, row.last!)
}

let table = ohlc.map {
	t in
	"\(t.0),\(t.1),\(t.2),\(t.3),\(t.4)"
}

do {
	try "T,O,H,L,C\n\(table.joined(separator: "\n"))".write(toFile: "ohlc.csv", atomically: false, encoding: .utf8)
} catch let error as NSError {
	print("Oopsie! \(error)")
}
