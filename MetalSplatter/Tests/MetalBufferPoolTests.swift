import XCTest
import Metal
@testable import MetalSplatter

final class MetalBufferPoolTests: XCTestCase {

    var device: MTLDevice!
    var pool: MetalBufferPool<Float>!

    override func setUp() {
        super.setUp()
        device = MTLCreateSystemDefaultDevice()
        XCTAssertNotNil(device, "Metal device should be available for testing")

        let config = MetalBufferPool<Float>.Configuration(
            maxPoolSize: 3,
            maxBufferAge: 5.0,
            memoryPressureThreshold: 0.8,
            enableMemoryPressureMonitoring: false // Disable for testing
        )
        pool = MetalBufferPool<Float>(device: device, configuration: config)
    }

    override func tearDown() {
        pool = nil
        device = nil
        super.tearDown()
    }

    func testBasicAcquireAndRelease() throws {
        // Test basic acquire/release cycle
        let buffer1 = try pool.acquire(minimumCapacity: 100)
        XCTAssertGreaterThanOrEqual(buffer1.capacity, 100)

        // Release and verify no crash
        pool.release(buffer1)
    }

    func testBufferReuse() throws {
        // Acquire and release a buffer
        let buffer1 = try pool.acquire(minimumCapacity: 100)
        let originalCapacity = buffer1.capacity
        pool.release(buffer1)

        // Acquire again with same capacity - should reuse the same buffer
        let buffer2 = try pool.acquire(minimumCapacity: 100)
        XCTAssertEqual(buffer2.capacity, originalCapacity)

        pool.release(buffer2)
    }

    func testPoolSizeLimit() throws {
        var buffers: [MetalBuffer<Float>] = []

        // Acquire more buffers than pool size
        for i in 0..<5 {
            let buffer = try pool.acquire(minimumCapacity: 100 + i * 10)
            buffers.append(buffer)
        }

        // Release all buffers
        for buffer in buffers {
            pool.release(buffer)
        }
    }

    func testCapacitySelection() throws {
        // Create buffers of different sizes
        let small = try pool.acquire(minimumCapacity: 50)
        pool.release(small)

        let large = try pool.acquire(minimumCapacity: 200)
        pool.release(large)

        // Request medium size - should get the smaller buffer that still fits
        let medium = try pool.acquire(minimumCapacity: 100)
        XCTAssertGreaterThanOrEqual(medium.capacity, 100)
        XCTAssertLessThan(medium.capacity, large.capacity) // Should prefer smaller suitable buffer

        pool.release(medium)
    }

    func testMemoryPressureCleanup() throws {
        // Fill pool with buffers
        let buffer1 = try pool.acquire(minimumCapacity: 100)
        pool.release(buffer1)

        let buffer2 = try pool.acquire(minimumCapacity: 200)
        pool.release(buffer2)

        let buffer3 = try pool.acquire(minimumCapacity: 300)
        pool.release(buffer3)

        // Trigger memory pressure cleanup - should not crash
        pool.trimToMemoryPressure()
    }

    func testWithBufferConvenience() throws {
        // Test the convenience method that auto-releases
        let result = try pool.withBuffer(minimumCapacity: 100) { buffer in
            XCTAssertGreaterThanOrEqual(buffer.capacity, 100)
            return "test_result"
        }

        XCTAssertEqual(result, "test_result")
    }

    func testInvalidCapacityHandling() {
        // Test handling of capacity larger than device maximum
        let maxCapacity = MetalBuffer<Float>.maxCapacity(for: device)

        XCTAssertThrowsError(try pool.acquire(minimumCapacity: maxCapacity + 1)) { error in
            guard case MetalBufferPool<Float>.PoolError.invalidCapacity = error else {
                XCTFail("Expected invalidCapacity error")
                return
            }
        }
    }
}
