//
//  JSONSerializable.swift
//  TPPDF
//
//  Created by Philip Niedertscheider on 12/08/2017.
//
//

import Foundation

public protocol TPJSONSerializable : TPJSONRepresentable { }

public extension TPJSONSerializable {
    
    public func toJSON(options: JSONSerialization.WritingOptions = []) -> String? {
        let representation = JSONRepresentation
        
        guard JSONSerialization.isValidJSONObject(representation) else {
            return nil
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: representation, options: options)
            return String(data: data, encoding: .utf8)
        } catch {
            print(error)
            return nil
        }
    }
}

extension TPJSONSerializable {
    
    public var JSONRepresentation: AnyObject {
        var representation = [String: AnyObject]()
        
        for case let (label?, value) in Mirror(reflecting: self).children {
            representation[label] = convertValue(value)
        }
        
        return representation as AnyObject
    }
}

extension TPJSONSerializable {
    
    func convertValue(_ value: Any) -> AnyObject {
        if let value = value as? TPJSONSerializable {
            return value.JSONRepresentation
        } else if let value = value as? NSObject {
            return value
        } else  if isTuple(value: value) {
            return serializeTuple(value)
        } else if Mirror(reflecting: value).displayStyle == .optional {
            return NSNull()
        } else {
            return "UNKNOWN" as NSString
        }
    }
    
    func isTuple(value: Any) -> Bool {
        return Mirror(reflecting: value).displayStyle == .tuple
    }
    
    func serializeTuple(_ value: Any) -> AnyObject {
        let mirror = Mirror(reflecting: value)
        var i = 0
        var result: [String : Any] = [:]
        
        for (label, value) in mirror.children {
            result[label ?? "\(i)"] = value
            i += 1
        }
        return result.JSONRepresentation
    }
}

extension Array : TPJSONSerializable {
    
    public var JSONRepresentation: AnyObject {
        var representation: [Any] = []
        
        for (value) in self {
            representation.append(convertValue(value))
        }
        
        return representation as NSArray
    }
}

extension Dictionary : TPJSONSerializable {
    
    public var JSONRepresentation: AnyObject {
        let representation: NSMutableDictionary = [:]
        
        for (key, value) in self {
            representation[key] = convertValue(value)
        }
        
        return representation as NSDictionary
    }
}

extension CGRect  : TPJSONSerializable { }
extension CGPoint : TPJSONSerializable { }
extension CGSize  : TPJSONSerializable { }

extension NSAttributedString : TPJSONSerializable { }
extension UIFont: TPJSONSerializable { }

extension UIImage : TPJSONSerializable {
    
    public var JSONRepresentation: AnyObject {
        return "IMAGE" as NSString
        //        return (UIImageJPEGRepresentation(self, 1.0)?.base64EncodedString() as? NSString) ?? NSNull()
    }
}

extension UIColor : TPJSONSerializable {
    
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb: Int = (Int)(r*255) << 16 | (Int)(g*255) << 8 | (Int)(b*255) << 0
        
        return String(format:"#%06x", rgb)
    }
    
    public var JSONRepresentation: AnyObject {
        return self.toHexString() as NSString
    }
}
