// Code generated by protoc-gen-gogo. DO NOT EDIT.
// source: speculod/reputation/v1/reputation_score.proto

package types

import (
	fmt "fmt"
	proto "github.com/cosmos/gogoproto/proto"
	io "io"
	math "math"
	math_bits "math/bits"
)

// Reference imports to suppress errors if they are not otherwise used.
var _ = proto.Marshal
var _ = fmt.Errorf
var _ = math.Inf

// This is a compile-time assertion to ensure that this generated file
// is compatible with the proto package it is being compiled against.
// A compilation error at this line likely means your copy of the
// proto package needs to be updated.
const _ = proto.GoGoProtoPackageIsVersion3 // please upgrade the proto package

// ReputationScore defines the ReputationScore message.
type ReputationScore struct {
	Address string `protobuf:"bytes,1,opt,name=address,proto3" json:"address,omitempty"`
	Score   string `protobuf:"bytes,2,opt,name=score,proto3" json:"score,omitempty"`
	GroupId string `protobuf:"bytes,3,opt,name=group_id,json=groupId,proto3" json:"group_id,omitempty"`
}

func (m *ReputationScore) Reset()         { *m = ReputationScore{} }
func (m *ReputationScore) String() string { return proto.CompactTextString(m) }
func (*ReputationScore) ProtoMessage()    {}
func (*ReputationScore) Descriptor() ([]byte, []int) {
	return fileDescriptor_ef1612a32bc706d4, []int{0}
}
func (m *ReputationScore) XXX_Unmarshal(b []byte) error {
	return m.Unmarshal(b)
}
func (m *ReputationScore) XXX_Marshal(b []byte, deterministic bool) ([]byte, error) {
	if deterministic {
		return xxx_messageInfo_ReputationScore.Marshal(b, m, deterministic)
	} else {
		b = b[:cap(b)]
		n, err := m.MarshalToSizedBuffer(b)
		if err != nil {
			return nil, err
		}
		return b[:n], nil
	}
}
func (m *ReputationScore) XXX_Merge(src proto.Message) {
	xxx_messageInfo_ReputationScore.Merge(m, src)
}
func (m *ReputationScore) XXX_Size() int {
	return m.Size()
}
func (m *ReputationScore) XXX_DiscardUnknown() {
	xxx_messageInfo_ReputationScore.DiscardUnknown(m)
}

var xxx_messageInfo_ReputationScore proto.InternalMessageInfo

func (m *ReputationScore) GetAddress() string {
	if m != nil {
		return m.Address
	}
	return ""
}

func (m *ReputationScore) GetScore() string {
	if m != nil {
		return m.Score
	}
	return ""
}

func (m *ReputationScore) GetGroupId() string {
	if m != nil {
		return m.GroupId
	}
	return ""
}

func init() {
	proto.RegisterType((*ReputationScore)(nil), "speculod.reputation.v1.ReputationScore")
}

func init() {
	proto.RegisterFile("speculod/reputation/v1/reputation_score.proto", fileDescriptor_ef1612a32bc706d4)
}

var fileDescriptor_ef1612a32bc706d4 = []byte{
	// 178 bytes of a gzipped FileDescriptorProto
	0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0xff, 0xe2, 0xd2, 0x2d, 0x2e, 0x48, 0x4d,
	0x2e, 0xcd, 0xc9, 0x4f, 0xd1, 0x2f, 0x4a, 0x2d, 0x28, 0x2d, 0x49, 0x2c, 0xc9, 0xcc, 0xcf, 0xd3,
	0x2f, 0x33, 0x44, 0xe2, 0xc5, 0x17, 0x27, 0xe7, 0x17, 0xa5, 0xea, 0x15, 0x14, 0xe5, 0x97, 0xe4,
	0x0b, 0x89, 0xc1, 0x94, 0xeb, 0x21, 0x14, 0xe8, 0x95, 0x19, 0x2a, 0xc5, 0x70, 0xf1, 0x07, 0xc1,
	0x05, 0x82, 0x41, 0x1a, 0x84, 0x24, 0xb8, 0xd8, 0x13, 0x53, 0x52, 0x8a, 0x52, 0x8b, 0x8b, 0x25,
	0x18, 0x15, 0x18, 0x35, 0x38, 0x83, 0x60, 0x5c, 0x21, 0x11, 0x2e, 0x56, 0xb0, 0x99, 0x12, 0x4c,
	0x60, 0x71, 0x08, 0x47, 0x48, 0x92, 0x8b, 0x23, 0xbd, 0x28, 0xbf, 0xb4, 0x20, 0x3e, 0x33, 0x45,
	0x82, 0x19, 0xa2, 0x01, 0xcc, 0xf7, 0x4c, 0x71, 0x32, 0x3d, 0xf1, 0x48, 0x8e, 0xf1, 0xc2, 0x23,
	0x39, 0xc6, 0x07, 0x8f, 0xe4, 0x18, 0x27, 0x3c, 0x96, 0x63, 0xb8, 0xf0, 0x58, 0x8e, 0xe1, 0xc6,
	0x63, 0x39, 0x86, 0x28, 0x69, 0xb8, 0xf3, 0x2b, 0x90, 0x3d, 0x50, 0x52, 0x59, 0x90, 0x5a, 0x9c,
	0xc4, 0x06, 0x76, 0xb3, 0x31, 0x20, 0x00, 0x00, 0xff, 0xff, 0xe0, 0x1c, 0x17, 0xe5, 0xe4, 0x00,
	0x00, 0x00,
}

func (m *ReputationScore) Marshal() (dAtA []byte, err error) {
	size := m.Size()
	dAtA = make([]byte, size)
	n, err := m.MarshalToSizedBuffer(dAtA[:size])
	if err != nil {
		return nil, err
	}
	return dAtA[:n], nil
}

func (m *ReputationScore) MarshalTo(dAtA []byte) (int, error) {
	size := m.Size()
	return m.MarshalToSizedBuffer(dAtA[:size])
}

func (m *ReputationScore) MarshalToSizedBuffer(dAtA []byte) (int, error) {
	i := len(dAtA)
	_ = i
	var l int
	_ = l
	if len(m.GroupId) > 0 {
		i -= len(m.GroupId)
		copy(dAtA[i:], m.GroupId)
		i = encodeVarintReputationScore(dAtA, i, uint64(len(m.GroupId)))
		i--
		dAtA[i] = 0x1a
	}
	if len(m.Score) > 0 {
		i -= len(m.Score)
		copy(dAtA[i:], m.Score)
		i = encodeVarintReputationScore(dAtA, i, uint64(len(m.Score)))
		i--
		dAtA[i] = 0x12
	}
	if len(m.Address) > 0 {
		i -= len(m.Address)
		copy(dAtA[i:], m.Address)
		i = encodeVarintReputationScore(dAtA, i, uint64(len(m.Address)))
		i--
		dAtA[i] = 0xa
	}
	return len(dAtA) - i, nil
}

func encodeVarintReputationScore(dAtA []byte, offset int, v uint64) int {
	offset -= sovReputationScore(v)
	base := offset
	for v >= 1<<7 {
		dAtA[offset] = uint8(v&0x7f | 0x80)
		v >>= 7
		offset++
	}
	dAtA[offset] = uint8(v)
	return base
}
func (m *ReputationScore) Size() (n int) {
	if m == nil {
		return 0
	}
	var l int
	_ = l
	l = len(m.Address)
	if l > 0 {
		n += 1 + l + sovReputationScore(uint64(l))
	}
	l = len(m.Score)
	if l > 0 {
		n += 1 + l + sovReputationScore(uint64(l))
	}
	l = len(m.GroupId)
	if l > 0 {
		n += 1 + l + sovReputationScore(uint64(l))
	}
	return n
}

func sovReputationScore(x uint64) (n int) {
	return (math_bits.Len64(x|1) + 6) / 7
}
func sozReputationScore(x uint64) (n int) {
	return sovReputationScore(uint64((x << 1) ^ uint64((int64(x) >> 63))))
}
func (m *ReputationScore) Unmarshal(dAtA []byte) error {
	l := len(dAtA)
	iNdEx := 0
	for iNdEx < l {
		preIndex := iNdEx
		var wire uint64
		for shift := uint(0); ; shift += 7 {
			if shift >= 64 {
				return ErrIntOverflowReputationScore
			}
			if iNdEx >= l {
				return io.ErrUnexpectedEOF
			}
			b := dAtA[iNdEx]
			iNdEx++
			wire |= uint64(b&0x7F) << shift
			if b < 0x80 {
				break
			}
		}
		fieldNum := int32(wire >> 3)
		wireType := int(wire & 0x7)
		if wireType == 4 {
			return fmt.Errorf("proto: ReputationScore: wiretype end group for non-group")
		}
		if fieldNum <= 0 {
			return fmt.Errorf("proto: ReputationScore: illegal tag %d (wire type %d)", fieldNum, wire)
		}
		switch fieldNum {
		case 1:
			if wireType != 2 {
				return fmt.Errorf("proto: wrong wireType = %d for field Address", wireType)
			}
			var stringLen uint64
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return ErrIntOverflowReputationScore
				}
				if iNdEx >= l {
					return io.ErrUnexpectedEOF
				}
				b := dAtA[iNdEx]
				iNdEx++
				stringLen |= uint64(b&0x7F) << shift
				if b < 0x80 {
					break
				}
			}
			intStringLen := int(stringLen)
			if intStringLen < 0 {
				return ErrInvalidLengthReputationScore
			}
			postIndex := iNdEx + intStringLen
			if postIndex < 0 {
				return ErrInvalidLengthReputationScore
			}
			if postIndex > l {
				return io.ErrUnexpectedEOF
			}
			m.Address = string(dAtA[iNdEx:postIndex])
			iNdEx = postIndex
		case 2:
			if wireType != 2 {
				return fmt.Errorf("proto: wrong wireType = %d for field Score", wireType)
			}
			var stringLen uint64
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return ErrIntOverflowReputationScore
				}
				if iNdEx >= l {
					return io.ErrUnexpectedEOF
				}
				b := dAtA[iNdEx]
				iNdEx++
				stringLen |= uint64(b&0x7F) << shift
				if b < 0x80 {
					break
				}
			}
			intStringLen := int(stringLen)
			if intStringLen < 0 {
				return ErrInvalidLengthReputationScore
			}
			postIndex := iNdEx + intStringLen
			if postIndex < 0 {
				return ErrInvalidLengthReputationScore
			}
			if postIndex > l {
				return io.ErrUnexpectedEOF
			}
			m.Score = string(dAtA[iNdEx:postIndex])
			iNdEx = postIndex
		case 3:
			if wireType != 2 {
				return fmt.Errorf("proto: wrong wireType = %d for field GroupId", wireType)
			}
			var stringLen uint64
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return ErrIntOverflowReputationScore
				}
				if iNdEx >= l {
					return io.ErrUnexpectedEOF
				}
				b := dAtA[iNdEx]
				iNdEx++
				stringLen |= uint64(b&0x7F) << shift
				if b < 0x80 {
					break
				}
			}
			intStringLen := int(stringLen)
			if intStringLen < 0 {
				return ErrInvalidLengthReputationScore
			}
			postIndex := iNdEx + intStringLen
			if postIndex < 0 {
				return ErrInvalidLengthReputationScore
			}
			if postIndex > l {
				return io.ErrUnexpectedEOF
			}
			m.GroupId = string(dAtA[iNdEx:postIndex])
			iNdEx = postIndex
		default:
			iNdEx = preIndex
			skippy, err := skipReputationScore(dAtA[iNdEx:])
			if err != nil {
				return err
			}
			if (skippy < 0) || (iNdEx+skippy) < 0 {
				return ErrInvalidLengthReputationScore
			}
			if (iNdEx + skippy) > l {
				return io.ErrUnexpectedEOF
			}
			iNdEx += skippy
		}
	}

	if iNdEx > l {
		return io.ErrUnexpectedEOF
	}
	return nil
}
func skipReputationScore(dAtA []byte) (n int, err error) {
	l := len(dAtA)
	iNdEx := 0
	depth := 0
	for iNdEx < l {
		var wire uint64
		for shift := uint(0); ; shift += 7 {
			if shift >= 64 {
				return 0, ErrIntOverflowReputationScore
			}
			if iNdEx >= l {
				return 0, io.ErrUnexpectedEOF
			}
			b := dAtA[iNdEx]
			iNdEx++
			wire |= (uint64(b) & 0x7F) << shift
			if b < 0x80 {
				break
			}
		}
		wireType := int(wire & 0x7)
		switch wireType {
		case 0:
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return 0, ErrIntOverflowReputationScore
				}
				if iNdEx >= l {
					return 0, io.ErrUnexpectedEOF
				}
				iNdEx++
				if dAtA[iNdEx-1] < 0x80 {
					break
				}
			}
		case 1:
			iNdEx += 8
		case 2:
			var length int
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return 0, ErrIntOverflowReputationScore
				}
				if iNdEx >= l {
					return 0, io.ErrUnexpectedEOF
				}
				b := dAtA[iNdEx]
				iNdEx++
				length |= (int(b) & 0x7F) << shift
				if b < 0x80 {
					break
				}
			}
			if length < 0 {
				return 0, ErrInvalidLengthReputationScore
			}
			iNdEx += length
		case 3:
			depth++
		case 4:
			if depth == 0 {
				return 0, ErrUnexpectedEndOfGroupReputationScore
			}
			depth--
		case 5:
			iNdEx += 4
		default:
			return 0, fmt.Errorf("proto: illegal wireType %d", wireType)
		}
		if iNdEx < 0 {
			return 0, ErrInvalidLengthReputationScore
		}
		if depth == 0 {
			return iNdEx, nil
		}
	}
	return 0, io.ErrUnexpectedEOF
}

var (
	ErrInvalidLengthReputationScore        = fmt.Errorf("proto: negative length found during unmarshaling")
	ErrIntOverflowReputationScore          = fmt.Errorf("proto: integer overflow")
	ErrUnexpectedEndOfGroupReputationScore = fmt.Errorf("proto: unexpected end of group")
)
