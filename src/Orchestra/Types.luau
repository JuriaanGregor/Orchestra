--!strict
--!nolint LocalUnused
--!nolint LocalShadow

export type Version = {
	major: number,
	minor: number,
	isRelease: boolean,
	build: string?,
}

export type Wire<T> = {
	type: "Wire",
	kind: "Component",
}

export type WireContructor = <T, S>(
) -> Wire<T>

export type PropertyTable = {
    [string]: unknown
}

export type AttributeTable = {
    [string]: unknown
}

export type SpecialKey = {
	type: "SpecialKey",
	kind: string
}

export type Component = {
	type: "Component",
	kind: string
}

export type NewConstructor = (
	className: string
) -> (propertyTable: PropertyTable) -> Instance

export type Orchestra = {
	Version: Version,
	Components: { [string]: any },
    New: NewConstructor,
}

return nil
